import AppKit
import Carbon
import Foundation

enum SystemDictationShortcutReader {
    static let symbolicHotKeyID = "164"

    static func readFromDefaults() -> CaptureShortcut? {
        guard let hotKeys = UserDefaults.standard.dictionary(forKey: "AppleSymbolicHotKeys") else {
            return nil
        }
        return shortcut(from: hotKeys)
    }

    static func shortcut(from hotKeys: [String: Any]) -> CaptureShortcut? {
        guard let entry = hotKeys[symbolicHotKeyID] as? [String: Any],
              (entry["enabled"] as? Bool) == true,
              let value = entry["value"] as? [String: Any],
              let parameters = value["parameters"] as? [Any],
              parameters.count >= 3,
              let characterCode = intValue(parameters[0]),
              let keyCode = intValue(parameters[1]),
              let cocoaModifiers = intValue(parameters[2]) else {
            return nil
        }

        let modifiers = carbonModifiers(fromCocoaModifierRawValue: cocoaModifiers)
        let label = label(
            forKeyCode: UInt32(keyCode),
            characterCode: characterCode,
            modifiers: modifiers
        )
        return CaptureShortcut(keyCode: UInt32(keyCode), modifiers: modifiers, label: label)
    }

    static func carbonModifiers(fromCocoaModifierRawValue rawValue: Int) -> UInt32 {
        var modifiers: UInt32 = 0
        let flags = NSEvent.ModifierFlags(rawValue: UInt(rawValue))

        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }

        return modifiers
    }

    private static func label(forKeyCode keyCode: UInt32, characterCode: Int, modifiers: UInt32) -> String {
        let character = UnicodeScalar(characterCode).map { String($0) }
        let keyLabel = ShortcutRecorder.keyLabel(for: keyCode, characters: character)
        let modifierLabel = ShortcutRecorder.modifierLabels(fromCarbonModifiers: modifiers)
        return (modifierLabel + [keyLabel]).joined(separator: " + ")
    }

    private static func intValue(_ value: Any) -> Int? {
        if let int = value as? Int {
            return int
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        return nil
    }
}
