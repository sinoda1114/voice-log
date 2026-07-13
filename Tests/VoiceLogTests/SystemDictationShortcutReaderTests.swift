import Carbon
import XCTest
@testable import VoiceLog

final class SystemDictationShortcutReaderTests: XCTestCase {
    func testParsesEnabledDictationShortcutFromSymbolicHotKeys() {
        let hotKeys: [String: Any] = [
            "164": [
                "enabled": true,
                "value": [
                    "parameters": [
                        99,
                        8,
                        786432
                    ],
                    "type": "standard"
                ]
            ]
        ]

        XCTAssertEqual(
            SystemDictationShortcutReader.shortcut(from: hotKeys),
            CaptureShortcut(
                keyCode: 8,
                modifiers: UInt32(controlKey | optionKey),
                label: "Control + Option + C"
            )
        )
    }

    func testReturnsNilWhenDictationShortcutIsDisabled() {
        let hotKeys: [String: Any] = [
            "164": [
                "enabled": false
            ]
        ]

        XCTAssertNil(SystemDictationShortcutReader.shortcut(from: hotKeys))
    }
}
