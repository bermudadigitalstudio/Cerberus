import XCTest
@testable import Cerberus

class LiveVaultTests: XCTestCase {

    static var allTests = [
        ("testUnreachableVault", testUnreachableVault),
        ("testVaultStatus", testVaultStatus),
        ("testtRootToken", testtRootToken),
        ("testPeriodicToken", testPeriodicToken),
        ("testRoleAndSecret", testRoleAndSecret)
    ]

    var vaultURL: URL!

    override func setUp() {
        super.setUp()

        vaultURL = URL(string: "http://localhost:8200")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testUnreachableVault() {
        guard let vaultFailingURL = URL(string: "http://localhost:8201") else {
            XCTFail("Can't init URL")
            return
        }
        let vaultClient = VaultClient(vaultAuthority: vaultFailingURL)
        XCTAssertThrowsError(try vaultClient.status())
    }

    func testVaultStatus() throws {
        let vaultClient = VaultClient(vaultAuthority: vaultURL)
        XCTAssertFalse(try vaultClient.status().sealed)
        XCTAssertTrue(try vaultClient.status().healthy)
    }

    func testtRootToken() throws {

        guard let rootToken = ProcessInfo.processInfo.environment["ROOT_TOKEN"] else {
            XCTFail("can't find ROOT_TOKEN env")
            return
        }

        let vaultClient = VaultClient(vaultAuthority: vaultURL)
        vaultClient.token = rootToken
        XCTAssertNoThrow(try vaultClient.checkToken())

        // can list policies attached to the token
        let policies = try vaultClient.listPolicies()
        XCTAssertEqual(policies.first, "root")

        // can store and retrieve secrets
        let secret = ["some_private_secret": UUID().uuidString]
        XCTAssertNoThrow(try vaultClient.store(secret, atPath: "/foo/bar/cerberus/private"))

        let secretRead = try vaultClient.secret(atPath: "/foo/bar/cerberus/private")
        XCTAssertEqual(secretRead, secret)
    }

    func testPeriodicToken() throws {
        guard let periodicToken = ProcessInfo.processInfo.environment["PERIODIC_TOKEN"] else {
            XCTFail("can't find PERIODIC_TOKEN env")
            return
        }

        guard let accessibleSecretPath = ProcessInfo.processInfo.environment["ACCESSIBLE_SECRET_PATH"] else {
            XCTFail("can't find ACCESSIBLE_SECRET_PATH env")
            return
        }

        let vaultClient = VaultClient(vaultAuthority: vaultURL)
        vaultClient.token = periodicToken
        XCTAssertNoThrow(try vaultClient.checkToken())

        // can list policies attached to the token

        let policies = try vaultClient.listPolicies()
        XCTAssertTrue(policies.contains("default"))

        // can discover the ttl date of the token
        let ttl = try vaultClient.tokenTTL()
        XCTAssertGreaterThan(ttl, 0)

        XCTAssertNoThrow(try vaultClient.renewToken())
        let newTTL = try vaultClient.tokenTTL()
        XCTAssertGreaterThan(newTTL, ttl)

        // returns an error when attempting to retrieve impermissible secrets
        XCTAssertThrowsError(try vaultClient.secret(atPath: "/foo/bar/cerberus/private"))

        // can retrieve a permissible secret
        let secret = try vaultClient.secret(atPath: accessibleSecretPath)
        XCTAssertTrue(secret.keys.contains("secret"))
    }

    func testRoleAndSecret() throws {
        guard let roleID = ProcessInfo.processInfo.environment["ROLE_ID"] else {
            XCTFail("can't find ROLE_ID env")
            return
        }

        guard let secretID = ProcessInfo.processInfo.environment["SECRET_ID"] else {
            XCTFail("can't find SECRET_ID env")
            return
        }

        guard let accessibleSecretPath = ProcessInfo.processInfo.environment["ACCESSIBLE_SECRET_PATH"] else {
            XCTFail("can't find ACCESSIBLE_SECRET_PATH env")
            return
        }

        // authenticating with a role ID and secret ID
        let vaultClient = VaultClient(vaultAuthority: vaultURL)
        XCTAssertNoThrow(try vaultClient.authenticate(roleID: roleID, secretID: secretID))

        // can authenticate and retrieve a token
        XCTAssertNotNil(vaultClient.token)

        // can retrieve a permissible secret
        let secret = try vaultClient.secret(atPath: accessibleSecretPath)
        XCTAssertTrue(secret.keys.contains("secret"))
    }

}
