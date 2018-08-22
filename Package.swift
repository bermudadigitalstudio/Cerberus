// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Cerberus",
    products: [
        .library(name: "Cerberus", targets: ["Cerberus"])
    ],
    dependencies: [
        .package(url: "https://github.com/bermudadigitalstudio/Log.git", .upToNextMinor(from: "0.0.1"))
    ],
    targets:[
        .target(name:"Cerberus", dependencies: ["Log"]),
        .testTarget(name: "CerberusTests", dependencies: ["Cerberus"])
    ]
)
