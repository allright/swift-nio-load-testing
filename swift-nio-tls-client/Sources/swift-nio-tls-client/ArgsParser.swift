//
// Created by Andrey Syvrachev on 2019-03-04.
//

import Foundation


enum ConnectTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

func targetFromCommandLine() -> ConnectTo {
    let arguments = CommandLine.arguments
    // First argument is the program path
    let arg1 = arguments.dropFirst().first
    let arg2 = arguments.dropFirst().dropFirst().first

    let defaultHost = "::1"
    let defaultPort: Int = 9999


    let connectTarget: ConnectTo
    switch (arg1, arg1.flatMap(Int.init), arg2.flatMap(Int.init)) {
    case (.some(let h), _, .some(let p)):
        /* we got two arguments, let's interpret that as host and port */
        connectTarget = .ip(host: h, port: p)
    case (.some(let portString), .none, _):
        /* couldn't parse as number, expecting unix domain socket path */
        connectTarget = .unixDomainSocket(path: portString)
    case (_, .some(let p), _):
        /* only one argument --> port */
        connectTarget = .ip(host: defaultHost, port: p)
    default:
        connectTarget = .ip(host: defaultHost, port: defaultPort)
    }
    return connectTarget
}