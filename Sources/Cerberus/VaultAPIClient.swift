import Foundation
import Dispatch

private let session = URLSession(configuration: .default)

struct Sys {
    static func health(vaultAuthority: URL) throws -> [String: Any] {
        let health = vaultAuthority.appendingPathComponent("/v1/sys/health")

        let r = try fetchJSON(health)
        guard let dict = r as? [String: Any] else {
            throw VaultCommunicationError.parseError
        }
        return dict
    }
}

struct Auth {

    struct Token {
        static func lookupSelf(vaultAuthority: URL, token: String) throws -> [String: Any] {
            let lookupSelf = vaultAuthority.appendingPathComponent("/v1/auth/token/lookup-self")
            guard let r = try fetchJSON(lookupSelf, token: token) as? [String: Any] else {
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
        static func login(vaultAuthority: URL, roleID: String,
                          secretID: String? = nil, backendMountPoint: String = "/auth/approle") throws -> [String: Any] {

            let login = vaultAuthority.appendingPathComponent("/v1").appendingPathComponent(backendMountPoint).appendingPathComponent("/login")
            var payload = [
                "role_id": roleID
            ]
            if let s = secretID {
                payload["secret_id"] = s
            }
            guard let json = try postAndReceiveJSON(login, json: payload) as? [String: Any] else {
                throw VaultCommunicationError.parseError
            }
            return json
        }
    }

}

struct Secret {
    struct Database {
        static func credentials(vaultAuthority: URL, token: String,
                                role: String, backendMountPoint: String = "/database") throws -> [String: Any] {

            let read = vaultAuthority.appendingPathComponent("/v1")
                .appendingPathComponent(backendMountPoint)
                .appendingPathComponent("/creds/")
                .appendingPathComponent(role)

            guard let dict = try fetchJSON(read, token: token) as? [String: Any] else {
                throw VaultCommunicationError.parseError
            }
            return dict
        }
    }
    struct Generic {
        static func store(vaultAuthority: URL, token: String, secret: [String: String], path: String, backendMountPoint: String = "/secret") throws {
            let store = vaultAuthority.appendingPathComponent("/v1").appendingPathComponent(backendMountPoint).appendingPathComponent(path)
            try postJSON(store, json: secret, token: token)
        }
        static func read(vaultAuthority: URL, token: String, path: String, backendMountPoint: String = "/secret") throws -> [String: Any] {
            let read = vaultAuthority.appendingPathComponent("/v1").appendingPathComponent(backendMountPoint).appendingPathComponent(path)
            guard let dict = try fetchJSON(read, token: token) as? [String: Any] else {
                throw VaultCommunicationError.parseError
            }
            return dict
        }
    }
}

private func fetchJSON(_ url: URL, token: String? = nil) throws -> Any {
    let request = requestForURL(url, token: token)

    var error: Error?
    var json: Any?

    let sema = DispatchSemaphore(value: 0)
    session.dataTask(with: request, completionHandler: { (data, _, err) in
        if let err = err {
            error = err
        } else if let data = data {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
            } catch let jsonError {
                error = jsonError
            }
        }

        sema.signal()
    }).resume()

    let timeout = sema.wait(wallTimeout: .now() + .seconds(30))

    switch timeout {
    case .timedOut:
        throw VaultCommunicationError.timedOut
    case.success:
        if let error = error {
            throw VaultCommunicationError.connectionError(error)
        } else if let json = json {
            return json
        } else {
            throw VaultCommunicationError.parseError
        }
    }
}

private func postJSON(_ url: URL, json: Any, token: String? = nil) throws {
    var request = requestForURL(url, token: token)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let data = try JSONSerialization.data(withJSONObject: json, options: [])

    var error: Error?

    let sema = DispatchSemaphore(value: 0)
    session.uploadTask(with: request, from: data, completionHandler: { (_, _, err) in
        error = err
        sema.signal()
    }).resume()

    let timeout = sema.wait(wallTimeout: .now() + .seconds(30))

    switch timeout {
    case .timedOut:
        throw VaultCommunicationError.timedOut
    case.success:
        if let error = error {
            throw VaultCommunicationError.connectionError(error)
        }
    }
}

private func postAndReceiveJSON(_ url: URL, json: Any, token: String? = nil) throws -> Any {
    var request = requestForURL(url, token: token)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let data = try JSONSerialization.data(withJSONObject: json, options: [])

    var error: Error?
    var json: Any?

    let sema = DispatchSemaphore(value: 0)
    session.uploadTask(with: request, from: data, completionHandler: { (data, _, err) in
        if let err = err {
            error = err
        } else if let data = data {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
            } catch let jsonError {
                error = jsonError
            }
        }

        sema.signal()
    }).resume()

    let timeout = sema.wait(wallTimeout: .now() + .seconds(30))

    switch timeout {
    case .timedOut:
        throw VaultCommunicationError.timedOut
    case.success:
        if let error = error {
            throw VaultCommunicationError.connectionError(error)
        } else if let json = json {
            return json
        } else {
            throw VaultCommunicationError.parseError
        }
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
