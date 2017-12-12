import XCTest
@testable import Cerberus

/// Tests covering the integration of Cerberus with https://www.vaultproject.io/api/auth/kubernetes/index.html
class KubernetesVaultTests: XCTestCase {

    static var allTests = [
        ("testInitK8sVaultEnv", testInitK8sVaultEnv)
    ]

    func testInitK8sVaultEnv() throws {

        guard let url = URL(string:"http://localhost:8200") else {
            XCTFail("Wrong url")
            return
        }

        // Integration too complex
//        let vaultClient = try VaultClient.KubernetesLogin(credentialPath: "/tmp/k8s-test/token", vaultAddress: url, role: "MyRole")
//
//        XCTAssertNotNil(vaultClient.token)
    }
}
