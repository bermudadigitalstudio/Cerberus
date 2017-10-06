import Foundation
import Quick
import Nimble
import Cerberus

final class MockVaultClient: VaultClientTokenRenewable {
    var fakeTokenTTL = 5
    func lookupSelfTokenData() throws -> [String: Any] {
        return [
            "ttl": fakeTokenTTL,
            "renewable": true
        ]
    }
    var tokenRenewalsCalled = 0
    func renewToken() throws {
        fakeTokenTTL = 5
        tokenRenewalsCalled += 1
    }
    deinit {
        print("wtf")
    }
    var renewalManager: RenewalManager! = nil
}

/// Tests covering Cerberus' automatic token renewal. These tests expect a running vault.
final class AutoRenewalTests: QuickSpec {
  override func spec() {
    describe("the renewal manager") {
        context("initialized with a mock vault client") {
            var theRenewalManager: RenewalManager! = nil
            var aMockVaultClient: MockVaultClient! = nil
            beforeEach {
                aMockVaultClient = MockVaultClient()
                theRenewalManager = RenewalManager(vaultClient: aMockVaultClient)
                aMockVaultClient.renewalManager = theRenewalManager
            }
            it("can autorenew") {
                expect {
                    try theRenewalManager.beginRenewal()
                }.toNot(throwError())
            }
            context("with autorenew enabled") {
                beforeEach {
                    expect {
                        try theRenewalManager.beginRenewal()
                    }.toNot(throwError())
                }
                it("calls renew before the time expires") {
                    expect {
                        aMockVaultClient.tokenRenewalsCalled
                    }.toEventually(beGreaterThan(0), timeout: 3)
                }
            }

        }
    }
    describe("automatic token renewal") {
      var theVaultClient: VaultClient! = nil
      beforeEach {
        theVaultClient = VaultClient()
      }
      describe("when trying to enable without a token") {
        beforeEach {
          theVaultClient.token = nil
        }
        it("fails to enable") {
          expect {
            try theVaultClient.enableAutoRenew()
          }.to(throwError())
        }
      }
      describe("when trying to enable with a periodic token") {
        beforeEach {
          theVaultClient.token = PeriodicToken
        }
        it("enables") {
          expect {
            try theVaultClient.enableAutoRenew()
          }.toNot(throwError())
        }
        context("with autorenew enabled") {
            beforeEach {
                expect {
                    try theVaultClient.enableAutoRenew()
                }.toNot(throwError())
            }
            tryIt("it schedules a renewal before the expiration") {
                let ttl = try theVaultClient.tokenTTL()
                expect(theVaultClient.renewalManager?.timeToRenew).to(beLessThan(ttl))
            }
        }
      }
    }
  }
}
