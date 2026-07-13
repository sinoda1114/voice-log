import SwiftUI

@main
@MainActor
struct VoiceLogApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        MenuBarExtra {
            Button("新規入力を開く") {
                controller.windowManager.openCaptureWindow(
                    store: controller.store,
                    autoStartDictation: controller.store.autoStartsDictation,
                    dictationShortcut: controller.store.dictationShortcut
                )
            }
            .keyboardShortcut("n")

            Button("履歴を開く") {
                controller.windowManager.openHistoryWindow(store: controller.store)
            }
            .keyboardShortcut("h")

            Button("最新履歴をコピー") {
                controller.store.copyLatestEntry()
            }
            .disabled(controller.store.entries.isEmpty)

            Divider()

            Button("保存フォルダを開く") {
                controller.store.openStorageFolder()
            }

            Button("設定") {
                controller.windowManager.openSettingsWindow(store: controller.store)
            }

            Divider()

            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "text.bubble")
        }
        .menuBarExtraStyle(.menu)
    }
}
