// swift-tools-version:3.1

import PackageDescription

let package = Package(
  name: "Cerberus",
  dependencies: [
    .Package(url: "https://github.com/bermudadigitalstudio/ServerKit.git", majorVersion: 0, minor: 0)
  ]
)
#if os(Linux)
let quick = Package.Dependency.Package(url: "https://github.com/Quick/Quick", majorVersion: 1, minor: 1)
let nimble = Package.Dependency.Package(url: "https://github.com/Quick/Nimble", majorVersion: 7, minor: 0)
let tests = Target(name: "TestIntegration", dependencies: ["Cerberus"])
package.dependencies.append(quick)
package.dependencies.append(nimble)
package.targets.append(tests)
#endif
