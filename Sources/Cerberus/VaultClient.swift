import Foundation
import ServerKit
import Dispatch

public enum VaultCommunicationError: Error {
    case connectionError(Error)
    case timedOut
    case parseError
    case notAuthorized
    case tokenNotSet
    case nonRenewableToken
}

public final class VaultClient {
    public let vaultAuthority: URL
    public let logger: Logger?
    private let session = URLSession(configuration: .default)
    public var token: String?
    public var renewalManager: RenewalManager?

    public init(vaultAuthority: URL, logger: Logger? = nil) {
        self.vaultAuthority = vaultAuthority
        self.logger = logger
    }

    public func status() throws -> (sealed: Bool, healthy: Bool) {
        let dict = try Sys.health(vaultAuthority: vaultAuthority)
        let sealed = dict["sealed"] as? Bool ?? false
        return (sealed, true)
    }

    /// Configures automatic renewal
    public func enableAutoRenew() throws {
        self.renewalManager = RenewalManager(vaultClient: self, logger: self.logger)
        try self.renewalManager?.beginRenewal()
    }
}

/// Inspecting the currently set token
extension VaultClient {
    public func checkToken() throws {
        _ = try lookupSelfTokenData()
    }

    public func tokenTTL() throws -> Int {
        let data = try lookupSelfTokenData()
        guard let ttl = data["ttl"] as? Int else {
            throw VaultCommunicationError.parseError
        }
        return ttl
    }

    public func lookupSelfTokenData() throws -> [String: Any] {
        let d = try Auth.Token.lookupSelf(vaultAuthority: vaultAuthority, token: getToken())
        guard let data = d["data"] as? [String: Any] else {
            throw VaultCommunicationError.parseError
        }
        return data
    }

    public func listPolicies() throws -> [String] {
        let data = try lookupSelfTokenData()
        guard let policies = data["policies"] as? [String] else {
            throw VaultCommunicationError.parseError
        }
        return policies
    }

    public func renewToken() throws {
        try Auth.Token.renewSelf(vaultAuthority: vaultAuthority, token: getToken())
    }
}

/// Interface to Generic
extension VaultClient {
    public func store(_ secret: [String: String], atPath path: String) throws {
        try Secret.Generic.store(vaultAuthority: vaultAuthority, token: getToken(), secret: secret, path: path)
    }

    public func secret(atPath path: String) throws -> [String: String] {
        let dict = try Secret.Generic.read(vaultAuthority: vaultAuthority, token: getToken(), path: path)
        guard let data = dict["data"] as? [String: String] else {
            throw VaultCommunicationError.parseError
        }
        return data
    }
}

/// Interface to AppRole
extension VaultClient {
    public func authenticate(roleID: String, secretID: String? = nil) throws {
        let dict = try Auth.AppRole.login(vaultAuthority: vaultAuthority, roleID: roleID, secretID: secretID)
        guard let auth = dict["auth"] as? [String: Any], let token = auth["client_token"] as? String else {
            throw VaultCommunicationError.parseError
        }
        self.token = token
    }
}

/// Interface to Database
extension VaultClient {
    public func databaseCredentials(forRole databaseRole: String) throws -> (username: String, password: String) {
        let dict = try Secret.Database.credentials(vaultAuthority: vaultAuthority, token: getToken(), role: databaseRole)
        guard let data = dict["data"] as? [String: String],
            let password = data["password"],
            let username = data["username"] else {
                throw VaultCommunicationError.parseError
        }

        return (username, password)
    }
}

private extension VaultClient {
    func getToken() throws -> String {
        guard let t = token else { throw VaultCommunicationError.tokenNotSet }
        return t
    }
}

extension VaultClient: VaultClientTokenRenewable {}
