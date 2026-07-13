import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var requiresModifier = true
    let onRecord: (CaptureShortcut) -> Void

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.requiresModifier = requiresModifier
        view.onRecord = { shortcut in
            onRecord(shortcut)
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.isRecording = isRecording
        nsView.requiresModifier = requiresModifier
        nsView.onRecord = { shortcut in
            onRecord(shortcut)
            isRecording = false
        }

        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class RecorderNSView: NSView {
        var isRecording = false
        var requiresModifier = true
        var onRecord: ((CaptureShortcut) -> Void)?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func keyDown(with event: NSEvent) {
            guard isRecording else {
                super.keyDown(with: event)
                return
            }

            if let shortcut = ShortcutRecorder.shortcut(from: event, requiresModifier: requiresModifier) {
                onRecord?(shortcut)
            }
        }
    }
}
