// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Cerberus",
    products: [
        .library(name: "Cerberus", targets: ["Cerberus"])
    ],
    targets:[
        .target(name:"Cerberus", dependencies: []),
        .testTarget(name: "CerberusTests", dependencies: ["Cerberus"])
    ]
)
