import Dispatch

public protocol VaultClientTokenRenewable: class {
    func lookupSelfTokenData() throws -> [String:Any]
    func renewToken() throws
}
public final class RenewalManager {
    unowned let vaultClient: VaultClientTokenRenewable
    public init(vaultClient: VaultClientTokenRenewable) {
        self.vaultClient = vaultClient
    }

    public var timeToRenew: Int? = nil

    public func beginRenewal() throws {
        let tokenData = try self.vaultClient.lookupSelfTokenData()
        guard let ttl = tokenData["ttl"] as? Int, let renewable = tokenData["renewable"] as? Bool, renewable else {
            throw VaultCommunicationError.nonRenewableToken
        }
        let timeToRenew = ttl/2
        self.timeToRenew = timeToRenew
        let time = DispatchTime.now() + .seconds(timeToRenew)
        DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
            guard let strongSelf = self else { return }
            do {
                strongSelf.timeToRenew = nil
                try strongSelf.vaultClient.renewToken()
                try strongSelf.beginRenewal()
            } catch {
                print("Got error: \(error)")
            }
        }
    }
}
