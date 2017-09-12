import Foundation

enum KubernetesVaultError: Error {
  case CredentialsNotFound
  case ParseJSONError
}
extension VaultClient {
  public static func autologin(credentialDirectory: String = "/var/run/secrets/boostport.com") throws -> VaultClient {
    guard let vaultTokenData = FileManager().contents(atPath: credentialDirectory + "/vault-token") else {
      throw KubernetesVaultError.CredentialsNotFound
    }
    guard let json = try JSONSerialization.jsonObject(with: vaultTokenData, options: []) as? [String:Any] else {
      throw KubernetesVaultError.ParseJSONError
    }
    guard let authority = json["vaultAddr"] as? String, let url = URL(string: authority), let token = json["clientToken"] as? String else {
      throw KubernetesVaultError.ParseJSONError
    }
    let client = VaultClient(vaultAuthority: url)
    client.token = token
    return client
  }
}