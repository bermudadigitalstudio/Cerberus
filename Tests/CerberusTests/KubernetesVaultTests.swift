import XCTest
@testable import Cerberus

/// Tests covering the integration of Cerberus with https://github.com/Boostport/kubernetes-vault
class KubernetesVaultTests: XCTestCase {

    static var allTests = [
        ("testInitK8sVaultEnv", testInitK8sVaultEnv)
    ]

    let credPath = "/tmp/var/run/secrets/boostport.com"
    var vaultURL: URL!

    override func setUp() {
        super.setUp()

        vaultURL = URL(string: "http://localhost:8200")

        do {
            try FileManager().createDirectory(atPath: credPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Can't create temp directory")
        }
    }

    func testInitK8sVaultEnv() throws {
        guard let periodicToken = ProcessInfo.processInfo.environment["PERIODIC_TOKEN"] else {
            XCTFail("can't find PERIODIC_TOKEN env")
            return
        }

        let vaultTokenContents = "{\"clientToken\":\"\(periodicToken)\",\"accessor\":\"SOME RANDOM ACCESSOR\",\"leaseDuration\":3600," +
                                 "\"renewable\":true, \"vaultAddr\":\"http://localhost:8200\"}"
        try vaultTokenContents.write(toFile: credPath + "/vault-token", atomically: true, encoding: .utf8)

        let vaultClient = try VaultClient.autologin(credentialDirectory: credPath)

        XCTAssertEqual(vaultClient.vaultAuthority, vaultURL)
        XCTAssertNotNil(vaultClient.token)

    }
}
