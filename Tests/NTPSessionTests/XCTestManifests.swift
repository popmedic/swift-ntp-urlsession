import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(NTPTests.allTests),
        testCase(NTPTaskTests.allTests)
    ]
}
#endif
