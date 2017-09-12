// swift-tools-version:3.1

import PackageDescription

let package = Package(
  name: "Cerberus",
  dependencies: [
    .Package(url: "https://github.com/bermudadigitalstudio/ServerKit.git", majorVersion: 0, minor: 0)
  ]
)
