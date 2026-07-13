import Combine
import Foundation

@MainActor
final class AppController: ObservableObject {
    let store: VoiceLogStore
    let windowManager: WindowManager

    private let globalHotKey: GlobalHotKey
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let store = VoiceLogStore()
        let windowManager = WindowManager()

        self.store = store
        self.windowManager = windowManager
        self.globalHotKey = GlobalHotKey()

        registerShortcut(store.captureShortcut)

        store.$captureShortcut
            .dropFirst()
            .sink { [weak self] shortcut in
                self?.registerShortcut(shortcut)
            }
            .store(in: &cancellables)
    }

    private func registerShortcut(_ shortcut: CaptureShortcut) {
        globalHotKey.registerCaptureShortcut(shortcut) { [weak self] in
            guard let self else { return }
            windowManager.openCaptureWindow(
                store: store,
                autoStartDictation: store.autoStartsDictation,
                dictationShortcut: store.dictationShortcut
            )
        }
    }
}
