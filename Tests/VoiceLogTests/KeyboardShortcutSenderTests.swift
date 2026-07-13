import Carbon
import XCTest
@testable import VoiceLog

final class KeyboardShortcutSenderTests: XCTestCase {
    func testMapsCarbonModifiersToCGEventFlags() {
        let flags = KeyboardShortcutSender.cgEventFlags(
            from: UInt32(cmdKey | optionKey | controlKey | shiftKey)
        )

        XCTAssertTrue(flags.contains(.maskCommand))
        XCTAssertTrue(flags.contains(.maskAlternate))
        XCTAssertTrue(flags.contains(.maskControl))
        XCTAssertTrue(flags.contains(.maskShift))
    }

    func testMapsNoModifiersToEmptyFlags() {
        XCTAssertTrue(KeyboardShortcutSender.cgEventFlags(from: 0).isEmpty)
    }

    func testBuildsCGEventsForShortcut() {
        let shortcut = CaptureShortcut(
            keyCode: UInt32(kVK_ANSI_D),
            modifiers: UInt32(cmdKey | optionKey),
            label: "Command + Option + D"
        )
        let events = KeyboardShortcutSender.events(for: shortcut)

        XCTAssertNotNil(events.keyDown)
        XCTAssertNotNil(events.keyUp)
        XCTAssertTrue(events.keyDown?.flags.contains(.maskCommand) == true)
        XCTAssertTrue(events.keyDown?.flags.contains(.maskAlternate) == true)
    }
}
