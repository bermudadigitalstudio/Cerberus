import Foundation
import Quick
import Nimble
import Cerberus

/// Tests covering the integration of Cerberus with https://github.com/Boostport/kubernetes-vault
final class KubernetesVaultTests: QuickSpec {
  override func spec() {
    describe("running in a k8s vault environment") {
      let credPath = "/tmp/var/run/secrets/boostport.com"
      beforeEach {
        expect {
          try FileManager().createDirectory(atPath: credPath, withIntermediateDirectories: true, attributes: nil)
        }.toNot(throwError())
      }
      context("with a vault-token file") {
        var theVaultClient: VaultClient!
        beforeEach {
          let vaultTokenContents = "{\n   \"clientToken\":\"91526d9b-4850-3405-02a8-aa29e74e17a5\",\n   \"accessor\":\"476ea048-ded5-4d07-eeea-938c6b4e43ec\",\n   \"leaseDuration\":3600,\n   \"renewable\":true,\n   \"vaultAddr\":\"https://vault:8200\"\n}\n"
          expect {
            try vaultTokenContents.write(toFile: credPath + "/vault-token", atomically: true, encoding: .utf8)
          }.toNot(throwError())
          expect {
            theVaultClient = try VaultClient.autologin(credentialDirectory: credPath)
          }.toNot(throwError())
        }
        it("can initialize a vault client") {
          expect(theVaultClient).toNot(beNil())
          expect(theVaultClient?.token).toNot(beNil())
          expect(theVaultClient?.vaultAuthority).to(equal(URL(string: "https://vault:8200")!))
        }
      }
    }
  }
}
