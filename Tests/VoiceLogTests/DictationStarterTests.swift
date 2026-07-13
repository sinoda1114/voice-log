import AppKit
import XCTest
@testable import VoiceLog

@MainActor
final class DictationStarterTests: XCTestCase {
    func testUsesStartDictationSelector() {
        XCTAssertEqual(
            NSStringFromSelector(DictationStarter.startDictationSelector),
            "startDictation:"
        )
    }
}
