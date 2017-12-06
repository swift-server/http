import Dispatch
import Foundation
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif


/// A server socket can accept peers. Each accepted peer get's it own socket after accepting.
internal final class TCPServer {
    /// The dispatch queue that peers are accepted on.
    let queue: DispatchQueue

    /// This server's event loops.
    /// Configuring these using the eventLoopCount at init.
    /// These will be supplied to requests at they arrive.
    let eventLoops: [DispatchQueue]

    /// This server's TCP socket.
    private let socket: TCPSocket

    /// A round robin view into the event loop array.
    private var eventLoopsIterator: LoopIterator<[DispatchQueue]>

    /// Keep a reference to the read source so it doesn't deallocate
    private var readSource: DispatchSourceRead?

    /// Creates a TCP server from an existing TCP socket.
    init(socket: TCPSocket, eventLoops: [DispatchQueue]) {
        self.socket = socket
        self.queue = DispatchQueue(label: "org.swift.server.accept", qos: .background)
        self.eventLoops = eventLoops
        self.eventLoopsIterator = LoopIterator(collection: eventLoops)
    }

    /// A closure that can dictate if a client will be accepted
    ///
    /// `true` for accepted, `false` for not accepted
    typealias AcceptHandler = (TCPClient) -> ()

    /// Starts listening for peers asynchronously
    ///
    /// - parameter maxIncomingConnections: The maximum backlog of incoming connections. Defaults to 4096.
    func start(hostname: String = "0.0.0.0", port: UInt16, backlog: Int32 = 4096, onAccept: @escaping AcceptHandler) throws {
        try socket.bind(hostname: hostname, port: port)
        try socket.listen(backlog: backlog)

        let source = DispatchSource.makeReadSource(
            fileDescriptor: socket.descriptor,
            queue: queue
        )

        source.setEventHandler {
            let socket: TCPSocket
            do {
                socket = try self.socket.accept()
            } catch {
                print(error)
                return
            }

            let eventLoop = self.eventLoopsIterator.next()!
            /// FIXME: pass worker
            let client = TCPClient(socket: socket, on: eventLoop)
            onAccept(client)
        }

        source.resume()
        readSource = source
    }

    /// See CloseableStream.close
    func close() {
        socket.close()
    }
}



/// TCP client stream.
internal final class TCPClient {
    /// This client's dispatch queue. Use this
    /// for all async operations performed as a
    /// result of this client.
    let eventLoop: DispatchQueue

    /// The client stream's underlying socket.
    private(set) var socket: TCPSocket

    /// Bytes from the socket are read into this buffer.
    /// Views into this buffer supplied to output streams.
    let outputBuffer: UnsafeMutableBufferPointer<UInt8>

    /// Data being fed into the client stream is stored here.
    var inputBuffer = [Data]()

    /// Stores read event source.
    var readSource: DispatchSourceRead?

    /// Stores write event source.
    var writeSource: DispatchSourceWrite?

    /// Keeps track of the writesource's active status so it's not resumed too often
    var isWriting = false

    //// Close handler
    typealias OnClose = () -> ()

    /// Called when this client closes
    var onClose: OnClose?

    /// Creates a new Remote Client from the a socket
    init(socket: TCPSocket, on eventLoop: DispatchQueue) {
        self.socket = socket
        self.eventLoop = eventLoop

        // Allocate one TCP packet
        let size = 1024 // 65_507
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        self.outputBuffer = UnsafeMutableBufferPointer<UInt8>(start: pointer, count: size)
    }

    convenience init(on eventLoop: DispatchQueue) throws {
        let socket = try TCPSocket()
        socket.disablePipeSignal()
        self.init(socket: socket, on: eventLoop)
    }

    /// See InputStream.onInput
    func write(_ input: UnsafeBufferPointer<UInt8>) {
        do {
            let count = try socket.write(from: input)

            guard count == input.count else {
                let data = Data(input[input.count...])

                inputBuffer.append(data)
                ensureWriteSourceResumed()
                return
            }
        } catch {
            inputBuffer.append(Data(input))
            ensureWriteSourceResumed()
        }
    }

    /// Handles DispatchData input
    func write(_ input: DispatchData) {
        inputBuffer.append(Data(input))
        ensureWriteSourceResumed()
    }

    /// Handles Data input
    func write(_ input: Data) {
        inputBuffer.append(input)
        ensureWriteSourceResumed()
    }

    private func ensureWriteSourceResumed() {
        if !isWriting {
            ensureWriteSource().resume()
            isWriting = true
        }
    }

    /// Creates a new WriteSource is there is no write source yet
    private func ensureWriteSource() -> DispatchSourceWrite {
        guard let source = writeSource else {
            let source = DispatchSource.makeWriteSource(
                fileDescriptor: socket.descriptor,
                queue: eventLoop
            )

            source.setEventHandler {
                // grab input buffer
                guard self.inputBuffer.count > 0 else {
                    self.writeSource?.suspend()
                    return
                }

                let data = self.inputBuffer.removeFirst()

                if self.inputBuffer.count == 0 {
                    // important: make sure to suspend or else writeable
                    // will keep calling.
                    self.writeSource?.suspend()

                    self.isWriting = false
                }

                data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
                    let buffer = UnsafeBufferPointer<UInt8>(start: pointer, count: data.count)

                    do {
                        let length = try self.socket.write(from: buffer)

                        if length < buffer.count {
                            self.inputBuffer.insert(Data(buffer[length...]), at: 0)
                        }
                    } catch {
                        // any errors that occur here cannot be thrown,
                        // so send them to stream error catcher.
                        /// FIXME: catch
                        print(error)
                    }
                }
            }

            source.setCancelHandler {
                self.close()
            }

            writeSource = source
            return source
        }

        return source
    }

    /// Handles incoming bytes
    typealias ReadHandler = (UnsafeBufferPointer<UInt8>) -> ()

    /// Starts receiving data from the client
    func start(onRead: @escaping ReadHandler) {
        let source = DispatchSource.makeReadSource(
            fileDescriptor: socket.descriptor,
            queue: eventLoop
        )

        source.setEventHandler {
            let read: Int
            do {
                read = try self.socket.read(
                    max: self.outputBuffer.count,
                    into: self.outputBuffer.baseAddress!
                )
            } catch {
                // any errors that occur here cannot be thrown,
                // so send them to stream error catcher.
                /// FIXME: catch
                print(error)
                return
            }

            guard read > 0 else {
                // need to close!!! gah
                source.cancel()
                return
            }

            // create a view into our internal buffer and
            // send to the output stream
            let bufferView = UnsafeBufferPointer<UInt8>(
                start: self.outputBuffer.baseAddress,
                count: read
            )
            onRead(bufferView)
        }

        source.setCancelHandler {
            self.close()
        }

        source.resume()
        readSource = source
    }

    /// Closes the client.
    func close() {
        // important!!!!!!
        // for some reason you can't cancel a suspended write source
        // if you remove this line, your life will be ruined forever!!!
        if self.inputBuffer.count == 0 {
            writeSource?.resume()
        }

        readSource = nil
        writeSource = nil

        socket.close()
        onClose?()
    }

    /// Deallocated the pointer buffer
    deinit {
        close()
        outputBuffer.baseAddress.unsafelyUnwrapped.deallocate(capacity: outputBuffer.count)
        outputBuffer.baseAddress.unsafelyUnwrapped.deinitialize()
    }
}

/// Any TCP socket. It doesn't specify being a server or client yet.
internal struct TCPSocket {
    /// The file descriptor related to this socket
    let descriptor: Int32

    /// True if the socket is non blocking
    let isNonBlocking: Bool

    /// True if the socket should re-use addresses
    let shouldReuseAddress: Bool

    /// The socket's address
    var address: Address?

    /// A read source that's used to check when the connection is readable
    internal var readSource: DispatchSourceRead?

    /// A write source that's used to check when the connection is open
    internal var writeSource: DispatchSourceWrite?

    /// Creates a TCP socket around an existing descriptor
    init(
        established: Int32,
        isNonBlocking: Bool,
        shouldReuseAddress: Bool,
        address: Address?
    ) {
        self.descriptor = established
        self.isNonBlocking = isNonBlocking
        self.shouldReuseAddress = shouldReuseAddress
        self.address = address
    }

    /// Creates a new TCP socket
    init(
        isNonBlocking: Bool = true,
        shouldReuseAddress: Bool = true
    ) throws {
        let sockfd = socket(AF_INET, SOCK_STREAM, 0)
        guard sockfd > 0 else {
            throw TCPError.posix(errno, identifier: "socketCreate")
        }

        if isNonBlocking {
            // Set the socket to async/non blocking I/O
            guard fcntl(sockfd, F_SETFL, O_NONBLOCK) == 0 else {
                throw TCPError.posix(errno, identifier: "setNonBlocking")
            }
        }

        if shouldReuseAddress {
            var yes = 1
            let intSize = socklen_t(MemoryLayout<Int>.size)
            guard setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, intSize) == 0 else {
                throw TCPError.posix(errno, identifier: "setReuseAddress")
            }
        }

        self.init(
            established: sockfd,
            isNonBlocking: isNonBlocking,
            shouldReuseAddress: shouldReuseAddress,
            address: nil
        )
    }

    func disablePipeSignal() {
        signal(SIGPIPE, SIG_IGN)

        #if !os(Linux)
            var n = 1
            setsockopt(self.descriptor, SOL_SOCKET, SO_NOSIGPIPE, &n, numericCast(MemoryLayout<Int>.size))
        #endif
    }

    /// Closes the socket
    func close() {
        #if os(Linux)
            Glibc.close(descriptor)
        #else
            Darwin.close(descriptor)
        #endif
    }

    /// Returns a boolean describing if the socket is still healthy and open
    var isConnected: Bool {
        var error = 0
        getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &error, nil)

        return error == 0
    }
}


extension TCPSocket {
    /// bind - bind a name to a socket
    /// http://man7.org/linux/man-pages/man2/bind.2.html
    func bind(hostname: String = "0.0.0.0", port: UInt16) throws {
        var hints = addrinfo()

        // Support both IPv4 and IPv6
        hints.ai_family = AF_INET

        // Specify that this is a TCP Stream
        hints.ai_socktype = SOCK_STREAM
        hints.ai_protocol = IPPROTO_TCP

        // If the AI_PASSIVE flag is specified in hints.ai_flags, and node is
        // NULL, then the returned socket addresses will be suitable for
        // bind(2)ing a socket that will accept(2) connections.
        hints.ai_flags = AI_PASSIVE


        // Look ip the sockeaddr for the hostname
        var result: UnsafeMutablePointer<addrinfo>?

        var res = getaddrinfo(hostname, port.description, &hints, &result)
        guard res == 0 else {
            throw TCPError.posix(
                errno,
                identifier: "getAddressInfo",
                possibleCauses: [
                    "The address that binding was attempted on does not refer to your machine."
                ],
                suggestedFixes: [
                    "Bind to `0.0.0.0` or to your machine's IP address"
                ]
            )
        }
        defer {
            freeaddrinfo(result)
        }

        guard let info = result else {
            throw TCPError(identifier: "unwrapAddress", reason: "Could not unwrap address info.")
        }

        #if os(Linux)
            res = Glibc.bind(descriptor, info.pointee.ai_addr, info.pointee.ai_addrlen)
        #else
            res = Darwin.bind(descriptor, info.pointee.ai_addr, info.pointee.ai_addrlen)
        #endif
        guard res == 0 else {
            throw TCPError.posix(errno, identifier: "bind")
        }
    }

    /// listen - listen for connections on a socket
    /// http://man7.org/linux/man-pages/man2/listen.2.html
    func listen(backlog: Int32 = 4096) throws {
        #if os(Linux)
            let res = Glibc.listen(descriptor, backlog)
        #else
            let res = Darwin.listen(descriptor, backlog)
        #endif
        guard res == 0 else {
            throw TCPError.posix(errno, identifier: "listen")
        }
    }

    /// accept, accept4 - accept a connection on a socket
    /// http://man7.org/linux/man-pages/man2/accept.2.html
    func accept() throws -> TCPSocket {
        let (clientfd, address) = try Address.withSockaddrPointer { address -> Int32 in
            var size = socklen_t(MemoryLayout<sockaddr>.size)

            #if os(Linux)
                let descriptor = Glibcaccept(self.descriptor, address, &size)
            #else
                let descriptor = Darwin.accept(self.descriptor, address, &size)
            #endif

            guard descriptor > 0 else {
                throw TCPError.posix(errno, identifier: "accept")
            }

            return descriptor
        }

        let socket = TCPSocket(
            established: clientfd,
            isNonBlocking: isNonBlocking,
            shouldReuseAddress: shouldReuseAddress,
            address: address
        )

        return socket
    }
}

extension TCPSocket {
    /// Writes all data from the pointer's position with the length specified to this socket.
    func write(from buffer: UnsafeBufferPointer<UInt8>) throws -> Int {
        guard let pointer = buffer.baseAddress else {
            return 0
        }

        let sent = send(descriptor, pointer, buffer.count, 0)
        guard sent != -1 else {
            switch errno {
            case EINTR:
                // try again
                return try write(from: buffer)
            case ECONNRESET, EBADF:
                // closed by peer, need to close this side.
                // Since this is not an error, no need to throw unless the close
                // itself throws an error.
                self.close()
                return 0
            default:
                throw TCPError.posix(errno, identifier: "write")
            }
        }

        return sent
    }

    /// Copies bytes into a buffer and writes them to the socket.
    func write(_ data: Data) throws -> Int {
        return try data.withByteBuffer(write)
    }
}

extension TCPSocket {
    /// Read data from the socket into the supplied buffer.
    /// Returns the amount of bytes actually read.
    func read(max: Int, into pointer: UnsafeMutablePointer<UInt8>) throws -> Int {
        #if os(Linux)
            let receivedBytes = Glibc.read(descriptor, pointer, max)
        #else
            let receivedBytes = Darwin.read(descriptor, pointer, max)
        #endif

        guard receivedBytes != -1 else {
            switch errno {
            case EINTR:
                // try again
                return try read(max: max, into: pointer)
            case ECONNRESET:
                // closed by peer, need to close this side.
                // Since this is not an error, no need to throw unless the close
                // itself throws an error.
                _ = close()
                return 0
            case EAGAIN:
                // timeout reached (linux)
                return 0
            default:
                throw TCPError.posix(errno, identifier: "read")
            }
        }

        guard receivedBytes > 0 else {
            // receiving 0 indicates a proper close .. no error.
            // attempt a close, no failure possible because throw indicates already closed
            // if already closed, no issue.
            // do NOT propogate as error
            _ = close()
            return 0
        }

        return receivedBytes
    }

    /// Reads bytes and copies them into a Data struct.
    func read(max: Int) throws -> Data {
        var data = Data(repeating: 0, count: max)

        let read = try data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
            return try self.read(max: max, into: pointer)
        }

        data.removeLast(data.count &- read)

        return data
    }
}

/// A socket address
struct Address {
    /// The raw underlying storage
    let storage: sockaddr_storage

    /// Creates a new socket address
    init(storage: sockaddr_storage) {
        self.storage = storage
    }

    /// Creates a new socket address
    init(storage: sockaddr) {
        var storage = storage

        self.storage = withUnsafePointer(to: &storage) { pointer in
            return pointer.withMemoryRebound(to: sockaddr_storage.self, capacity: 1) { storage in
                return storage.pointee
            }
        }
    }

    static func withSockaddrPointer<T>(
        do closure: ((UnsafeMutablePointer<sockaddr>) throws -> (T))
    ) rethrows -> (T, Address) {
        var addressStorage = sockaddr_storage()

        let other = try withUnsafeMutablePointer(to: &addressStorage) { pointer in
            return try pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                return try closure(socketAddress)
            }
        }

        let address = Address(storage: addressStorage)

        return (other, address)
    }
}

/// Infinitely loop over a collection.
/// Used to supply server worker queues to clients.
internal struct LoopIterator<Base: Collection>: IteratorProtocol {
    private let collection: Base
    private var index: Base.Index

    /// Create a new Loop Iterator from a collection.
    init(collection: Base) {
        self.collection = collection
        self.index = collection.startIndex
    }

    /// Get the next item in the loop iterator.
    mutating func next() -> Base.Iterator.Element? {
        guard !collection.isEmpty else {
            return nil
        }

        let result = collection[index]
        collection.formIndex(after: &index) // (*) See discussion below
        if index == collection.endIndex {
            index = collection.startIndex
        }
        return result
    }
}

extension Data {
    /// Reads from a `Data` buffer using a `BufferPointer` rather than a normal pointer
    func withByteBuffer<T>(_ closure: (UnsafeBufferPointer<UInt8>) throws -> T) rethrows -> T {
        return try self.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            let buffer = UnsafeBufferPointer<UInt8>(start: pointer,count: self.count)
            return try closure(buffer)
        }
    }
}


/// Errors that can be thrown while working with TCP sockets.
struct TCPError: Swift.Error, Encodable {
    static let readableName = "TCP Error"
    let identifier: String
    var reason: String
    var file: String
    var function: String
    var line: UInt
    var column: UInt
    var possibleCauses: [String]
    var suggestedFixes: [String]

    /// Create a new TCP error.
    init(
        identifier: String,
        reason: String,
        possibleCauses: [String] = [],
        suggestedFixes: [String] = [],
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.identifier = identifier
        self.reason = reason
        self.file = file
        self.function = function
        self.line = line
        self.column = column
        self.possibleCauses = possibleCauses
        self.suggestedFixes = suggestedFixes
    }

    /// Create a new TCP error from a POSIX errno.
    static func posix(
        _ errno: Int32,
        identifier: String,
        possibleCauses: [String] = [],
        suggestedFixes: [String] = [],
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) -> TCPError {
        let message = strerror(errno)
        let string = String(cString: message!, encoding: .utf8) ?? "unknown"
        return TCPError(
            identifier: identifier,
            reason: string,
            possibleCauses: possibleCauses,
            suggestedFixes: suggestedFixes,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}


#if os(Linux)
    import Glibc

    // fix some constants on linux
    let SOCK_STREAM = Int32(Glibc.SOCK_STREAM.rawValue)
    let IPPROTO_TCP = Int32(Glibc.IPPROTO_TCP)
#endif
