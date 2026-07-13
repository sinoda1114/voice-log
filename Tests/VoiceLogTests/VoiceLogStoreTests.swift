import Carbon
import XCTest
@testable import VoiceLog

@MainActor
final class VoiceLogStoreTests: XCTestCase {
    func testPersistsAndRestoresCustomCaptureShortcut() {
        let suiteName = "VoiceLogStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let tempFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoiceLogStoreTests-\(UUID().uuidString)", isDirectory: true)
        defaults.set(tempFolder.path, forKey: "storageFolderBookmarkPath")

        let customShortcut = CaptureShortcut(
            keyCode: UInt32(kVK_ANSI_L),
            modifiers: UInt32(cmdKey | optionKey),
            label: "Command + Option + L"
        )

        let firstStore = VoiceLogStore(defaults: defaults)
        firstStore.captureShortcut = customShortcut

        let secondStore = VoiceLogStore(defaults: defaults)
        XCTAssertEqual(secondStore.captureShortcut, customShortcut)
    }

    func testPersistsAndRestoresDictationShortcutAndAutoStartSetting() {
        let suiteName = "VoiceLogStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let tempFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoiceLogStoreTests-\(UUID().uuidString)", isDirectory: true)
        defaults.set(tempFolder.path, forKey: "storageFolderBookmarkPath")

        let dictationShortcut = CaptureShortcut(
            keyCode: UInt32(kVK_ANSI_D),
            modifiers: UInt32(controlKey),
            label: "Control + D"
        )

        let firstStore = VoiceLogStore(defaults: defaults)
        firstStore.dictationShortcut = dictationShortcut
        firstStore.autoStartsDictation = false

        let secondStore = VoiceLogStore(defaults: defaults)
        XCTAssertEqual(secondStore.dictationShortcut, dictationShortcut)
        XCTAssertFalse(secondStore.autoStartsDictation)
    }
}
