import Carbon
import Foundation

struct CaptureShortcut: Codable, Equatable, Hashable, Identifiable {
    let keyCode: UInt32
    let modifiers: UInt32
    let label: String

    var id: String {
        "\(keyCode)-\(modifiers)"
    }

    var storedValue: String {
        "\(keyCode):\(modifiers):\(label)"
    }

    var hasModifier: Bool {
        modifiers != 0
    }

    static let optionF5 = CaptureShortcut(
        keyCode: UInt32(kVK_F5),
        modifiers: UInt32(optionKey),
        label: "Option + F5"
    )

    static let f5 = CaptureShortcut(
        keyCode: UInt32(kVK_F5),
        modifiers: 0,
        label: "F5"
    )

    static let controlOptionSpace = CaptureShortcut(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(controlKey | optionKey),
        label: "Control + Option + Space"
    )

    static let commandOptionSpace = CaptureShortcut(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(cmdKey | optionKey),
        label: "Command + Option + Space"
    )

    static let commandOptionV = CaptureShortcut(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | optionKey),
        label: "Command + Option + V"
    )

    static let presets: [CaptureShortcut] = [
        .optionF5,
        .controlOptionSpace,
        .commandOptionSpace,
        .commandOptionV
    ]

    static let dictationPresets: [CaptureShortcut] = [
        .f5,
        .optionF5,
        .controlOptionSpace,
        .commandOptionSpace
    ]

    static func fromSavedValue(_ value: String?, default defaultShortcut: CaptureShortcut = .optionF5) -> CaptureShortcut {
        guard let value, !value.isEmpty else {
            return defaultShortcut
        }

        if let preset = (presets + dictationPresets).first(where: { $0.label == value }) {
            return preset
        }

        let parts = value.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3,
              let keyCode = UInt32(parts[0]),
              let modifiers = UInt32(parts[1]) else {
            return defaultShortcut
        }

        return CaptureShortcut(keyCode: keyCode, modifiers: modifiers, label: parts[2])
    }
}
