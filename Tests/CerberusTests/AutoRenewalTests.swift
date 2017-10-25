import XCTest
@testable import Cerberus

class AutoRenewalTests: XCTestCase {

    static var allTests = [
        ("testTokenRenewal", testTokenRenewal)
    ]

    var vaultURL: URL!

    override func setUp() {
        super.setUp()
        vaultURL = URL(string: "http://localhost:8200")
    }

    func testTokenRenewal() throws {
        guard let periodicToken = ProcessInfo.processInfo.environment["PERIODIC_TOKEN"] else {
            XCTFail("can't find PERIODIC_TOKEN env")
            return
        }

        let vaultClient = VaultClient(vaultAuthority: vaultURL)

        // when trying to enable without a token
        vaultClient.token = nil
        XCTAssertThrowsError(try vaultClient.enableAutoRenew())

        // when trying to enable with a periodic token
        vaultClient.token = periodicToken
        XCTAssertNoThrow(try vaultClient.enableAutoRenew())

        //it schedules a renewal before the expiration
        let ttl = try vaultClient.tokenTTL()
        guard let timeToRenew = vaultClient.renewalManager?.timeToRenew else {
            XCTFail("time to renew is nil")
            return
        }
        XCTAssertLessThan(timeToRenew, ttl)
    }

}
