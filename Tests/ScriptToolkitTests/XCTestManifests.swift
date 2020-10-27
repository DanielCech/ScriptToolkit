import XCTest

#if !os(macOS)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(ScriptToolkitTests.allTests),
        ]
    }
#endif
