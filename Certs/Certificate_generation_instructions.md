# Create self-signed certificate with openssl

```
// generate an RSA key
openssl genrsa -out key.pem 2048

// create cert signing request used to generate the cert
openssl req -new -sha256 -key key.pem -out cert.csr

// create cert
openssl req -x509 -sha256 -days 365 -key key.pem -in cert.csr -out cert.pem

// convert cert into PKCS#12 format:
openssl pkcs12 -export -out cert.pfx -inkey key.pem -in cert.pem
```
sw!ft!sC00l

Alternatively, use: https://www.sslshopper.com/ssl-converter.html

# Create certificate chain CA->intermediate->server
// Based on https://jamielinux.com/docs/openssl-certificate-authority/introduction.html
// Use above link to 

```
// create root key
openssl genrsa -out ca.key.pem 4096

//create root certificate
openssl req -config openssl.cnf -key ca.key.pem -new -x509 -days 7300 -sha256 extensions v3_ca -out ca.cert.pem

//verify root cert
openssl x509 -noout -text -in ca.cert.pem

// create intermediate key
openssl genrsa -out intermediate/intermediate.key.pem 4096

// create a certificate signing request
openssl req -config intermediate/openssl.cnf -new -sha256 -key intermediate/intermediate.key.pem -out intermediate/intermediate.csr.pem

// create certificate
openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in intermediate/intermediate.csr.pem -out intermediate/intermediate.cert.pem

// verify intermediate certificate
openssl x509 -noout -text -in intermediate/intermediate.cert.pem

// verify intermediate certificate against the root certificate
openssl verify -CAfile ca.cert.pem intermediate/intermediate.cert.pem

// create the certificate chain
cat intermediate/intermediate.cert.pem ca.cert.pem > intermediate/ca-chain.cert.pem

// create server key
openssl genrsa -out intermediate/server.key.pem 2048

openssl req -config intermediate/openssl.cnf -key intermediate/server.key.pem -new -sha256 -out intermediate/server.csr.pem

openssl ca -config intermediate/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in intermediate/server.csr.pem -out intermediate/server.cert.pem

// verify cert
openssl x509 -noout -text -in server.cert.pem

// verify chain of trust
openssl verify -CAfile ca-chain.cert.pem server.cert.pem


// Convert to PKCS12 for testing on mac
openssl pkcs12 -export -out certificate.pfx -inkey privateKey.key -in certificate.crt -certfile CACert.crt

or better yet! use: https://www.sslshopper.com/ssl-converter.html
```




