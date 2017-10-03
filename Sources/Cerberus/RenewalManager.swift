import Dispatch

public protocol VaultClientTokenRenewable: class {
    func lookupSelfTokenData() throws -> [String:Any]
    func renewToken() throws
}
public final class RenewalManager {
    unowned let vaultClient: VaultClientTokenRenewable
    let logger: Logger?
    public init(vaultClient: VaultClientTokenRenewable, logger: Logger? = nil) {
        self.vaultClient = vaultClient
	self.logger = logger
    }

    public var timeToRenew: Int? = nil

    public func beginRenewal() throws {
        let tokenData = try self.vaultClient.lookupSelfTokenData()
        guard let ttl = tokenData["ttl"] as? Int, let renewable = tokenData["renewable"] as? Bool, renewable else {
            throw VaultCommunicationError.nonRenewableToken
        }
        self.logger?.debug("Looked up self. TTL is \(ttl).")
        let timeToRenew = ttl/2
        self.timeToRenew = timeToRenew
	let logger = self.logger
        let time = DispatchTime.now() + .seconds(timeToRenew)
        DispatchQueue.global().asyncAfter(deadline: time) { [weak self] in
	    logger?.debug("Beginning renewal...")
            guard let strongSelf = self else {
	      logger?.debug("RenewalManager has deinitialized, aborting.")
	      return
	    }
            do {
                strongSelf.timeToRenew = nil
                logger?.debug("Renewing token...")
                try strongSelf.vaultClient.renewToken()
		logger?.debug("Renewed! Scheduling future renewal.")
                try strongSelf.beginRenewal()
            } catch {
                logger?.debug("Got error: \(error)")
            }
        }
	logger?.debug("Renewal scheduled for \(time)")
    }
}
