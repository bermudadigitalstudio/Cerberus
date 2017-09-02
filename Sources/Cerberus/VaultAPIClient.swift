struct Sys {
  static func health(vaultAuthority: URL) throws -> [String:Any] {
    let health = vaultAuthority.appendingPathComponent("/v1/sys/health")

    let r = try fetchJSON(health)
    guard let dict = r as? [String:Any] else {
      throw VaultCommunicationError.parseError
    }
    return dict
  }
}

struct Auth {
  struct Token {
    static func lookupSelf(vaultAuthority: URL, token: String) throws -> [String:Any] {
      let lookupSelf = vaultAuthority.appendingPathComponent("/v1/auth/token/lookup-self")
      guard let r = try fetchJSON(lookupSelf, token: token) as? [String:Any] else {
        throw VaultCommunicationError.parseError
      }
      return r
    }
  }
}

private func fetchJSON(_ url: URL, token: String? = nil) throws -> Any {
  let request: URLRequest
  if let t = token {
    var tokenReq = URLRequest(url: url)
    tokenReq.setValue(t, forHTTPHeaderField: "X-Vault-Token")
    request = tokenReq
  } else {
    request = URLRequest(url: url)
  }
  let x: SyncResult<Either<Any, Error>> = synchronize { completion in
    session.dataTask(with: request, completionHandler: { (data, resp, err) in
      completion(validateResponseIs2xxWithJSON(data: data, resp: resp, err: err))
    }).resume()
  }
  guard case .success(let result) = x else {
    throw VaultCommunicationError.timedOut
  }
  switch result {
  case .right:
    throw VaultCommunicationError.connectionError
  case .left(let r):
    return r
  }
}

private let session = URLSession(configuration: .default)
import Foundation
import ServerKit
