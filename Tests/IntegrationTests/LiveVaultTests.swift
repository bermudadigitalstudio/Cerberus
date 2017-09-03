import XCTest
import Cerberus
import Quick
import Nimble

let env = ProcessInfo.processInfo.environment
let RootToken: String = {
  guard let t = env["ROOT_TOKEN"] else {
    fatalError("Supply a `ROOT_TOKEN` env var with a root token to the Vault under test")
  }
  return t
}()

let LimitedToken: String = {
  guard let t = env["LIMITED_TOKEN"] else {
    fatalError("Supply a `LIMITED_TOKEN` env var with a root token to the Vault under test")
  }
  return t
}()

final class LiveVaultHTTPIntegrationTests: QuickSpec {
  override func spec() {
    describe("initializing cerberus to an unreachable vault") {
      var theVaultClient: VaultClient! = nil
      beforeEach {
        theVaultClient = VaultClient()
      }
      xit("cannot return status") {
        expect {
          try theVaultClient.status()
        }.to(throwError(errorType: VaultCommunicationError.self))
      }
    }
    describe("initializing cerberus to a sealed running vault") {
      var theVaultClient: VaultClient! = nil
      beforeEach {
        theVaultClient = VaultClient()
      }
      xit("can show the vault is sealed") {
        expect {
          try theVaultClient.status().sealed
        }.to(beTrue())
      }
    }
    describe("initializing cerberus to a unsealed running vault") {
      var theVaultClient: VaultClient! = nil
      beforeEach {
        theVaultClient = VaultClient()
      }
      it("can check if the vault is unsealed") {
        expect {
          try theVaultClient.status().sealed
        }.to(beFalse())
      }
      it("can check if the vault is healthy") {
        expect {
          try theVaultClient.status().healthy
        }.to(beTrue())
      }
      context("given a root token") {
        beforeEach {
          theVaultClient.token = RootToken
        }
        it("can authenticate with a given token") {
          expect {
            try theVaultClient.checkToken()
          }.toNot(throwError())
        }
        it("can list policies attached to the token") {
          expect {
            try theVaultClient.listPolicies()
          }.to(equal(["root"]))
        }
        it("can store and retrieve secrets") {
          let secret = ["some_private_secret": UUID().uuidString]
          expect {
            try theVaultClient.store(secret, atPath: "/foo/bar/cerberus/private")
            }.toNot(throwError())
          expect {
            try theVaultClient.secret(atPath: "/foo/bar/cerberus/private")
            }.to(equal(secret))
        }
      }
      context("given a limited scope token with only default policy") {
        beforeEach {
          theVaultClient.token = LimitedToken
        }
        it("can list policies attached to the token") {
          expect {
            try theVaultClient.listPolicies()
          }.to(equal(["default"]))
        }

        xit("returns an error when attempting to retrieve impermissible secrets") {
          XCTFail()
        }

        xit("can renew a token") {
          XCTFail()
        }
      }
      context("given a bad token") {
        xit("fails to authenticate with a bad token") {
          XCTFail()
        }
      }
    }
  }
}
