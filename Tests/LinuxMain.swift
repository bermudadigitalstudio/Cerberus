import XCTest
@testable import CerberusTests

XCTMain([
    testCase(KubernetesVaultTests.allTests),
    testCase(LiveVaultTests.allTests),
    testCase(AutoRenewalTests.allTests)
])
