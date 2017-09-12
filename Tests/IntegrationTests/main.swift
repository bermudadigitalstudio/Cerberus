import Quick
import XCTest

#if os(Linux)
QCKMain([
  LiveVaultHTTPIntegrationTests.self,
  KubernetesVaultTests.self,
  AutoRenewalTests.self
])
#endif
