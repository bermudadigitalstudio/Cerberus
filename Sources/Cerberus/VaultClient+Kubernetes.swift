import Foundation

enum KubernetesVaultError: Error {
    case credentialsNotFound
    case parseJSONError
}

extension VaultClient {
    public static func KubernetesLogin(credentialPath: String = "/var/run/secrets/kubernetes.io/serviceaccount/token",
                                 vaultAddress: URL, role: String, logger: Logger? = nil) throws -> VaultClient {

        guard let jwtTokenData = FileManager().contents(atPath: credentialPath), let jwt = String(data: jwtTokenData, encoding: .utf8) else {
            throw KubernetesVaultError.credentialsNotFound
        }

        let vaultLogin = ["role": role, "jwt": jwt]

        let client = VaultClient(vaultAuthority: vaultAddress, logger: logger)
        let vaultToken = try Kubernetes.login(vaultAuthority: vaultAddress, token: vaultLogin)

        guard let vaultAuth = vaultToken["auth"] as? [String: Any], let clientToken = vaultAuth["client_token"] as? String else {
            throw KubernetesVaultError.parseJSONError
        }

        client.token = clientToken

        try client.enableAutoRenew()
        return client
    }

}
