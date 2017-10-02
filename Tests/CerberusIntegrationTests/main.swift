import Quick
import XCTest

#if os(Linux)
QCKMain([
  LiveVaultHTTPCerberusIntegrationTests.self,
  KubernetesVaultTests.self,
  AutoRenewalTests.self
])
#endif
