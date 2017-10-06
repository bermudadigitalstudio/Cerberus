import XCTest
import Cerberus
import Quick
import Nimble

let env = ProcessInfo.processInfo.environment

func envOrFail(_ key: String) -> String {
  guard let t = env[key] else {
    fatalError("Supply a \(key) env var with to the Vault under test")
  }
  return t
}
let RootToken = envOrFail("ROOT_TOKEN")
let PeriodicToken: String = envOrFail("PERIODIC_TOKEN")
let AccessibleSecretPath: String = envOrFail("ACCESSIBLE_SECRET_PATH")

let RoleID = envOrFail("ROLE_ID")
let SecretID = envOrFail("SECRET_ID")

func tryIt(_ description: String, file: String = #file, line: UInt = #line, closure: @escaping () throws -> Swift.Void) {
  return it(description, file: file, line: line, closure: {
    do {
      try closure()
    } catch {
      XCTFail("Caught thrown error \(error)")
    }
  })
}

final class LiveVaultHTTPCerberusIntegrationTests: QuickSpec {
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
      context("given a periodic token with limited permissions") {
        beforeEach {
          theVaultClient.token = PeriodicToken
        }
        it("can list policies attached to the token") {
          expect {
            try theVaultClient.listPolicies()
          }.to(contain("default"))
        }

        it("can discover the ttl date of the token") {
          expect {
            try theVaultClient.tokenTTL()
          }.to(beGreaterThan(0)) // i.e. not infinite
        }

        tryIt("can renew the token") {
          let oldTTL = try theVaultClient.tokenTTL()
          sleep(1)
          try theVaultClient.renewToken() // expect token to now have a longer TTL than before
          expect {
            try theVaultClient.tokenTTL()
          }.to(beGreaterThan(oldTTL))
        }

        it("returns an error when attempting to retrieve impermissible secrets") {
          expect {
            try theVaultClient.secret(atPath: "/foo/bar/cerberus/private")
          }.to(throwError())
        }

        it("can retrieve a permissible secret") {
          expect {
            try theVaultClient.secret(atPath: AccessibleSecretPath)
          }.toNot(throwError())
          expect {
            try theVaultClient.secret(atPath: AccessibleSecretPath).keys
          }.to(contain("secret"))
        }
      }
      context("authenticating with a role ID and secret ID") {
        beforeEach {
          expect {
            try theVaultClient.authenticate(roleID: RoleID, secretID: SecretID)
          }.toNot(throwError())
        }
        it("can authenticate and retrieve a token") {
          expect(theVaultClient.token).toNot(beNil())
        }
        it("can retreive the special secret") {
          expect {
            try theVaultClient.secret(atPath: AccessibleSecretPath).keys
          }.to(contain("secret"))
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
