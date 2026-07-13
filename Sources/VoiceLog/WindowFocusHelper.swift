import AppKit

@MainActor
enum WindowFocusHelper {
    static func focusFirstTextView(in window: NSWindow) -> Bool {
        guard let textView = firstTextView(in: window.contentView) else {
            return false
        }

        window.makeFirstResponder(textView)
        return window.firstResponder === textView
    }

    static func firstTextView(in view: NSView?) -> NSTextView? {
        guard let view else {
            return nil
        }

        if let textView = view as? NSTextView {
            return textView
        }

        for subview in view.subviews {
            if let textView = firstTextView(in: subview) {
                return textView
            }
        }

        return nil
    }
}
