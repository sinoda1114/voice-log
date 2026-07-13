import Carbon
import Foundation

final class GlobalHotKey: @unchecked Sendable {
    private var eventHotKeys: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var action: (@MainActor () -> Void)?

    deinit {
        for eventHotKey in eventHotKeys {
            UnregisterEventHotKey(eventHotKey)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func registerCaptureShortcut(_ shortcut: CaptureShortcut, action: @escaping @MainActor () -> Void) {
        self.action = action
        unregisterHotKeys()

        guard ensureEventHandler() else {
            return
        }

        register(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers, id: 1, name: shortcut.label)
    }

    private func register(keyCode: UInt32, modifiers: UInt32, id: UInt32, name: String) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x564C4F47), id: id)
        var eventHotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )

        if status == noErr, let eventHotKey {
            eventHotKeys.append(eventHotKey)
        } else {
            NSLog("Failed to register \(name) hot key: \(status)")
        }
    }

    private func unregisterHotKeys() {
        for eventHotKey in eventHotKeys {
            UnregisterEventHotKey(eventHotKey)
        }
        eventHotKeys.removeAll()
    }

    private func ensureEventHandler() -> Bool {
        if eventHandler != nil {
            return true
        }

        let eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }

                let hotKey = Unmanaged<GlobalHotKey>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                Task { @MainActor in
                    hotKey.action?()
                }

                return noErr
            },
            1,
            [eventSpec],
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        if status != noErr {
            NSLog("Failed to install hot key handler: \(status)")
        }

        return status == noErr
    }
}
