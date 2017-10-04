# Swift Server Project HTTP APIs

This is an early implementation of the Swift Server Project's HTTP APIs. This provides simple HTTP server on which rich web application frameworks can be built.

## Getting Started


### Hello World
The following code implements a very simple "Hello World!" server:

```swift
import Foundation
import HTTP

func hello(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing { 
    response.writeHeader(status: .ok) 
    response.writeBody("Hello, World!") 
    response.done() 
    return .discardBody 
} 

let server = HTTPServer()
try! server.start(port: 8080, handler: hello)

RunLoop.current.run()
```

The `hello()` function receives a `HTTPRequest` that describes the request and a `HTTPResponseWriter` used to write a response. 

Data that is received as part of the request body is made available to the closure that is returned by the `hello()` function. In the "Hello World!" example the request body is not used, so `.discardBody` is returned.

### Echo Server
The following code implements a very simple Echo server that responds with the contents of the incoming request:

```swift
import Foundation
import HTTP

func echo(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
    response.writeHeader(status: .ok)
    return .processBody { (chunk, stop) in
        switch chunk {
        case .chunk(let data, let finishedProcessing):
            response.writeBody(data) { _ in
                finishedProcessing()
            }
        case .end:
            response.done()
        default:
            stop = true
            response.abort()
        }
    }
}

let server = HTTPServer()
try! server.start(port: 8080, handler: echo)

RunLoop.current.run()
```
As the Echo server needs to process the request body data and return it in the reponse, the `echo()` function returns a `.processBody` closure. This closure is called with `.chunk` when data is available for processing from the request, and `.end` when no more data is available.

Once any data chunk has been processed, `finishedProcessing()` should be called to signify that it has been handled.

When the response is complete, `response.done()` should be called.

## API Documentation
Full Jazzy documentation of the API is available here:  
<https://swift-server.github.io/http/>

## Contributing Feedback
We are actively seeking feedback on this prototype and your comments are extremely valuable. If you have any comments on the API design, the implementation, or any other aspects of this project, please email the [`swift-server-dev`](https://lists.swift.org/mailman/listinfo/swift-server-dev) mailing list.

## Acknowledgements
This project is based on an inital proposal from @weissi on the swift-server-dev mailing list:  
<https://lists.swift.org/pipermail/swift-server-dev/Week-of-Mon-20170403/000422.html>
