import AppKit
import SwiftUI

@MainActor
final class WindowManager: ObservableObject {
    private var captureWindows: [NSWindow] = []
    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var delegates: [ObjectIdentifier: NSWindowDelegate] = [:]

    func openCaptureWindow(
        store: VoiceLogStore,
        autoStartDictation: Bool = false,
        dictationShortcut: CaptureShortcut? = nil
    ) {
        let session = store.makeSession()
        let window = makeWindow(
            title: "Voice Log - 新規入力",
            size: NSSize(width: 480, height: 240),
            rootView: CaptureView(session: session)
        )
        captureWindows.append(window)
        let delegate = CaptureWindowDelegate(
            onClose: { [weak self, weak window, weak session] in
                session?.flush()
                guard let window else { return }
                self?.captureWindows.removeAll { $0 === window }
                self?.delegates.removeValue(forKey: ObjectIdentifier(window))
            }
        )
        window.delegate = delegate
        delegates[ObjectIdentifier(window)] = delegate
        show(window)

        if autoStartDictation, let dictationShortcut {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1200))
                guard window.isVisible, window.isKeyWindow else {
                    return
                }
                _ = WindowFocusHelper.focusFirstTextView(in: window)
                DictationStarter.start(fallbackShortcut: dictationShortcut)
            }
        }
    }

    func openHistoryWindow(store: VoiceLogStore) {
        if let historyWindow {
            show(historyWindow)
            store.reloadEntries()
            return
        }

        let window = makeWindow(
            title: "Voice Log - 履歴",
            size: NSSize(width: 840, height: 520),
            rootView: HistoryView(store: store)
        )
        let delegate = BasicWindowDelegate { [weak self, weak window] in
            self?.historyWindow = nil
            if let window {
                self?.delegates.removeValue(forKey: ObjectIdentifier(window))
            }
        }
        window.delegate = delegate
        delegates[ObjectIdentifier(window)] = delegate
        historyWindow = window
        show(window)
    }

    func openSettingsWindow(store: VoiceLogStore) {
        if let settingsWindow {
            show(settingsWindow)
            return
        }

        let window = makeWindow(
            title: "Voice Log - 設定",
            size: NSSize(width: 520, height: 260),
            rootView: SettingsView(store: store)
        )
        let delegate = BasicWindowDelegate { [weak self, weak window] in
            self?.settingsWindow = nil
            if let window {
                self?.delegates.removeValue(forKey: ObjectIdentifier(window))
            }
        }
        window.delegate = delegate
        delegates[ObjectIdentifier(window)] = delegate
        settingsWindow = window
        show(window)
    }

    private func makeWindow<Content: View>(title: String, size: NSSize, rootView: Content) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentView = NSHostingView(rootView: rootView)
        window.center()
        window.isReleasedWhenClosed = false
        return window
    }

    private func show(_ window: NSWindow) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private final class CaptureWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

private final class BasicWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
