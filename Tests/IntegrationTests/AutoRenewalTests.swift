import Foundation
import Quick
import Nimble
import Cerberus

/// Tests covering Cerberus' automatic token renewal. These tests expect a running vault with
final class AutoRenewalTests: QuickSpec {
  override func spec() {
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
      }
    }
  }
}
