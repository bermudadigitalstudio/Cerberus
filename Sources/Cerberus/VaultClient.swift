import Foundation
import ServerKit
public enum VaultCommunicationError: Error {
  case connectionError
  case timedOut
  case parseError
  case notAuthorized
}
public final class VaultClient {
  let vaultAuthority: URL
  let session = URLSession(configuration: .default)
  public var token: String? = nil
  public init(vaultAuthority: URL = URL(string: "http://localhost:8200")!) {
    self.vaultAuthority = vaultAuthority
  }

  public func status() throws -> (sealed: Bool, healthy: Bool) {
    let dict = try Sys.health(vaultAuthority: vaultAuthority)
    let sealed = dict["sealed"] as! Bool
    return (sealed, true)
  }

  public func checkToken() throws {
    guard let t = token else {
      throw VaultCommunicationError.notAuthorized
    }
    _ = try Auth.Token.lookupSelf(vaultAuthority: vaultAuthority, token: t)
  }

  public func listPolicies() throws -> [String] {
    guard let t = token else {
      throw VaultCommunicationError.notAuthorized
    }
    let d = try Auth.Token.lookupSelf(vaultAuthority: vaultAuthority, token: t)
    guard let data = d["data"] as? [String:Any] else {
      throw VaultCommunicationError.parseError
    }
    guard let policies = data["policies"] as? [String] else {
      throw VaultCommunicationError.parseError
    }
    return policies
  }
}

/// Interface to Generic
extension VaultClient {
  public func store(_ secret: [String:String], atPath path: String) throws {
    guard let t = token else {
      throw VaultCommunicationError.notAuthorized
    }
    try Secret.Generic.store(vaultAuthority: vaultAuthority, token: t, secret: secret, path: path)
  }

  public func secret(atPath path: String) throws -> [String:String] {
    guard let t = token else {
      throw VaultCommunicationError.notAuthorized
    }
    let dict = try Secret.Generic.read(vaultAuthority: vaultAuthority, token: t, path: path)
    guard let data = dict["data"] as? [String:String] else {
      throw VaultCommunicationError.parseError
    }
    return data
  }
}
