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

    static func renewSelf(vaultAuthority: URL, token: String) throws {
      let renewSelf = vaultAuthority.appendingPathComponent("/v1/auth/token/renew-self")
      try postJSON(renewSelf, json: [:], token: token)
      return
    }
  }
  struct AppRole {
    static func login(vaultAuthority: URL, roleID: String, secretID: String? = nil, backendMountPoint: String = "/auth/approle") throws -> [String:Any] {
      let login = vaultAuthority.appendingPathComponent("/v1").appendingPathComponent(backendMountPoint).appendingPathComponent("/login")
      var payload = [
        "role_id": roleID
      ]
      if let s = secretID {
        payload["secret_id"] = s
      }
      guard let json = try postAndReceiveJSON(login, json: payload) as? [String:Any] else {
        throw VaultCommunicationError.parseError
      }
      return json
    }
  }
}

struct Secret {
  struct Generic {
    static func store(vaultAuthority: URL, token: String, secret: [String:String], path: String, backendMountPoint: String = "/secret") throws {
      let store = vaultAuthority.appendingPathComponent("/v1").appendingPathComponent(backendMountPoint).appendingPathComponent(path)
      try postJSON(store, json: secret, token: token)
    }
    static func read(vaultAuthority: URL, token: String, path: String, backendMountPoint: String = "/secret") throws -> [String:Any] {
      let read = vaultAuthority.appendingPathComponent("/v1").appendingPathComponent(backendMountPoint).appendingPathComponent(path)
      guard let dict = try fetchJSON(read, token: token) as? [String:Any] else {
        throw VaultCommunicationError.parseError
      }
      return dict
    }
  }
}

private func fetchJSON(_ url: URL, token: String? = nil) throws -> Any {
  let request = requestForURL(url, token: token)
  let x: SyncResult<Either<Any, Error>> = synchronize { completion in
    session.dataTask(with: request, completionHandler: { (data, resp, err) in
      completion(validateResponseIs2xxWithJSON(data: data, resp: resp, err: err))
    }).resume()
  }
  guard case .success(let result) = x else {
    throw VaultCommunicationError.timedOut
  }
  switch result {
  case .right(let e):
    throw VaultCommunicationError.connectionError(e)
  case .left(let r):
    return r
  }
}

private func postJSON(_ url: URL, json: Any, token: String? = nil) throws {
  var request = requestForURL(url, token: token)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  let data = try JSONSerialization.data(withJSONObject: json, options: [])
  let x: SyncResult<Either<String?, Error>> = synchronize { completion in
    session.uploadTask(with: request, from: data, completionHandler: { (data, resp, err) in
      completion(validateResponseIs2xxString(data: data, resp: resp, err: err))
    }).resume()
  }
  guard case .success(let result) = x else {
    throw VaultCommunicationError.timedOut
  }
  switch result {
  case .right(let e):
    throw VaultCommunicationError.connectionError(e)
  case .left:
    return
  }
}

private func postAndReceiveJSON(_ url: URL, json: Any, token: String? = nil) throws -> Any {
  var request = requestForURL(url, token: token)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  let data = try JSONSerialization.data(withJSONObject: json, options: [])
  let x: SyncResult<Either<Any, Error>> = synchronize { completion in
    session.uploadTask(with: request, from: data, completionHandler: { (data, resp, err) in
      completion(validateResponseIs2xxWithJSON(data: data, resp: resp, err: err))
    }).resume()
  }
  guard case .success(let result) = x else {
    throw VaultCommunicationError.timedOut
  }
  switch result {
  case .right(let e):
    throw VaultCommunicationError.connectionError(e)
  case .left(let l):
    return l
  }
}

private func requestForURL(_ url: URL, token: String? = nil) -> URLRequest {
  let request: URLRequest
  if let t = token {
    var tokenReq = URLRequest(url: url)
    tokenReq.setValue(t, forHTTPHeaderField: "X-Vault-Token")
    request = tokenReq
  } else {
    request = URLRequest(url: url)
  }
  return request
}
private let session = URLSession(configuration: .default)
import Foundation
import ServerKit
