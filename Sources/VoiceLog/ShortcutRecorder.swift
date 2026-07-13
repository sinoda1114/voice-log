import AppKit
import Carbon

enum ShortcutRecorder {
    static func shortcut(from event: NSEvent, requiresModifier: Bool = true) -> CaptureShortcut? {
        let modifiers = carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 || !requiresModifier else {
            return nil
        }

        let keyLabel = keyLabel(for: UInt32(event.keyCode), characters: event.charactersIgnoringModifiers)
        guard !keyLabel.isEmpty else {
            return nil
        }

        let modifierLabel = modifierLabels(from: event.modifierFlags)
        let label = (modifierLabel + [keyLabel]).joined(separator: " + ")
        return CaptureShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers, label: label)
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
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

    static func modifierLabels(fromCarbonModifiers modifiers: UInt32) -> [String] {
        var labels: [String] = []
        if modifiers & UInt32(cmdKey) != 0 {
            labels.append("Command")
        }
        if modifiers & UInt32(controlKey) != 0 {
            labels.append("Control")
        }
        if modifiers & UInt32(optionKey) != 0 {
            labels.append("Option")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            labels.append("Shift")
        }
        return labels
    }

    private static func modifierLabels(from flags: NSEvent.ModifierFlags) -> [String] {
        var labels: [String] = []
        if flags.contains(.command) {
            labels.append("Command")
        }
        if flags.contains(.control) {
            labels.append("Control")
        }
        if flags.contains(.option) {
            labels.append("Option")
        }
        if flags.contains(.shift) {
            labels.append("Shift")
        }
        return labels
    }

    static func keyLabel(for keyCode: UInt32, characters: String?) -> String {
        switch Int(keyCode) {
        case kVK_Space:
            return "Space"
        case kVK_Return:
            return "Return"
        case kVK_Tab:
            return "Tab"
        case kVK_Escape:
            return "Escape"
        case kVK_Delete:
            return "Delete"
        default:
            if let functionKeyLabel = functionKeyLabels[Int(keyCode)] {
                return functionKeyLabel
            }
            return characters?.uppercased() ?? ""
        }
    }

    private static let functionKeyLabels: [Int: String] = [
        kVK_F1: "F1",
        kVK_F2: "F2",
        kVK_F3: "F3",
        kVK_F4: "F4",
        kVK_F5: "F5",
        kVK_F6: "F6",
        kVK_F7: "F7",
        kVK_F8: "F8",
        kVK_F9: "F9",
        kVK_F10: "F10",
        kVK_F11: "F11",
        kVK_F12: "F12",
        kVK_F13: "F13",
        kVK_F14: "F14",
        kVK_F15: "F15",
        kVK_F16: "F16",
        kVK_F17: "F17",
        kVK_F18: "F18",
        kVK_F19: "F19",
        kVK_F20: "F20"
    ]
}
