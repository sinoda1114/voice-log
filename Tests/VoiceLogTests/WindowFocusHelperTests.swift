import AppKit
import XCTest
@testable import VoiceLog

@MainActor
final class WindowFocusHelperTests: XCTestCase {
    func testFindsNestedTextView() {
        let root = NSView()
        let container = NSView()
        let textView = NSTextView()
        root.addSubview(container)
        container.addSubview(textView)

        XCTAssertTrue(WindowFocusHelper.firstTextView(in: root) === textView)
    }

    func testReturnsNilWhenTextViewIsMissing() {
        let root = NSView()
        root.addSubview(NSButton())

        XCTAssertNil(WindowFocusHelper.firstTextView(in: root))
    }
}
