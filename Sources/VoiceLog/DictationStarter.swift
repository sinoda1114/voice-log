import AppKit

@MainActor
enum DictationStarter {
    static let startDictationSelector = NSSelectorFromString("startDictation:")

    @discardableResult
    static func startUsingResponderAction() -> Bool {
        NSApp.sendAction(startDictationSelector, to: nil, from: nil)
    }

    static func start(fallbackShortcut: CaptureShortcut?) {
        if startUsingResponderAction() {
            return
        }

        if let fallbackShortcut {
            KeyboardShortcutSender.send(fallbackShortcut)
        }
    }
}
