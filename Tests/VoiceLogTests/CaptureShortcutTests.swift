import Carbon
import AppKit
import XCTest
@testable import VoiceLog

final class CaptureShortcutTests: XCTestCase {
    func testRoundTripsCustomShortcut() {
        let shortcut = CaptureShortcut(
            keyCode: UInt32(kVK_ANSI_L),
            modifiers: UInt32(cmdKey | optionKey | shiftKey),
            label: "Command + Option + Shift + L"
        )

        XCTAssertEqual(CaptureShortcut.fromSavedValue(shortcut.storedValue), shortcut)
    }

    func testRestoresLegacyPresetLabel() {
        XCTAssertEqual(CaptureShortcut.fromSavedValue("Option + F5"), .optionF5)
    }

    func testFallsBackToDefaultForInvalidValue() {
        XCTAssertEqual(CaptureShortcut.fromSavedValue("broken"), .optionF5)
    }

    func testBuildsShortcutFromKeyEvent() {
        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command, .option],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "l",
            charactersIgnoringModifiers: "l",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_L)
        )!

        XCTAssertEqual(
            ShortcutRecorder.shortcut(from: event),
            CaptureShortcut(
                keyCode: UInt32(kVK_ANSI_L),
                modifiers: UInt32(cmdKey | optionKey),
                label: "Command + Option + L"
            )
        )
    }

    func testIgnoresKeyEventWithoutModifiers() {
        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "l",
            charactersIgnoringModifiers: "l",
            isARepeat: false,
            keyCode: UInt16(kVK_ANSI_L)
        )!

        XCTAssertNil(ShortcutRecorder.shortcut(from: event))
    }

    func testBuildsBareFunctionKeyWhenModifierIsNotRequired() {
        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: UInt16(kVK_F5)
        )!

        XCTAssertEqual(
            ShortcutRecorder.shortcut(from: event, requiresModifier: false),
            .f5
        )
    }

    func testUsesProvidedDefaultForInvalidSavedValue() {
        XCTAssertEqual(CaptureShortcut.fromSavedValue("broken", default: .f5), .f5)
    }
}
