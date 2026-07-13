import Carbon
import Foundation
@preconcurrency import ApplicationServices

enum KeyboardShortcutSender {
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityPermissionIfNeeded() {
        guard !isAccessibilityTrusted else {
            return
        }

        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func send(_ shortcut: CaptureShortcut) {
        requestAccessibilityPermissionIfNeeded()
        guard isAccessibilityTrusted else {
            NSLog("Voice Log needs Accessibility permission before it can start dictation automatically.")
            return
        }

        post(shortcut, tap: .cghidEventTap)
        post(shortcut, tap: .cgSessionEventTap)
    }

    static func events(for shortcut: CaptureShortcut) -> (keyDown: CGEvent?, keyUp: CGEvent?) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(shortcut.keyCode),
            keyDown: true
        )
        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(shortcut.keyCode),
            keyDown: false
        )

        let flags = cgEventFlags(from: shortcut.modifiers)
        keyDown?.flags = flags
        keyUp?.flags = flags

        return (keyDown, keyUp)
    }

    static func cgEventFlags(from modifiers: UInt32) -> CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & UInt32(cmdKey) != 0 {
            flags.insert(.maskCommand)
        }
        if modifiers & UInt32(optionKey) != 0 {
            flags.insert(.maskAlternate)
        }
        if modifiers & UInt32(controlKey) != 0 {
            flags.insert(.maskControl)
        }
        if modifiers & UInt32(shiftKey) != 0 {
            flags.insert(.maskShift)
        }
        return flags
    }

    private static func post(_ shortcut: CaptureShortcut, tap: CGEventTapLocation) {
        let events = events(for: shortcut)
        events.keyDown?.post(tap: tap)
        events.keyUp?.post(tap: tap)
    }
}
