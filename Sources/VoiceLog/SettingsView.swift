import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: VoiceLogStore
    @State private var isRecordingShortcut = false
    @State private var isRecordingDictationShortcut = false
    @State private var accessibilityTrusted = KeyboardShortcutSender.isAccessibilityTrusted

    private var shortcutChoices: [CaptureShortcut] {
        if CaptureShortcut.presets.contains(store.captureShortcut) {
            return CaptureShortcut.presets
        }
        return [store.captureShortcut] + CaptureShortcut.presets
    }

    private var dictationShortcutChoices: [CaptureShortcut] {
        if CaptureShortcut.dictationPresets.contains(store.dictationShortcut) {
            return CaptureShortcut.dictationPresets
        }
        return [store.dictationShortcut] + CaptureShortcut.dictationPresets
    }

    var body: some View {
        Form {
            LabeledContent("起動ショートカット") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("候補", selection: $store.captureShortcut) {
                        ForEach(shortcutChoices) { shortcut in
                            Text(shortcut.label).tag(shortcut)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 240)

                    HStack {
                        ZStack(alignment: .leading) {
                            ShortcutRecorderView(isRecording: $isRecordingShortcut) { shortcut in
                                store.captureShortcut = shortcut
                            }
                            .frame(width: 1, height: 1)

                            Text(isRecordingShortcut ? "ショートカットを押してください" : store.captureShortcut.label)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(isRecordingShortcut ? .accentColor : .secondary)
                                .frame(minWidth: 240, alignment: .leading)
                        }

                        Button(isRecordingShortcut ? "入力待ち" : "記録") {
                            toggleShortcutRecording()
                        }
                    }
                }
            }

            LabeledContent("音声入力を自動開始") {
                Toggle("", isOn: $store.autoStartsDictation)
                    .labelsHidden()
            }

            LabeledContent("macOS音声入力ショートカット") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("候補", selection: $store.dictationShortcut) {
                        ForEach(dictationShortcutChoices) { shortcut in
                            Text(shortcut.label).tag(shortcut)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 240)

                    HStack {
                        ZStack(alignment: .leading) {
                            ShortcutRecorderView(isRecording: $isRecordingDictationShortcut, requiresModifier: false) { shortcut in
                                store.dictationShortcut = shortcut
                            }
                            .frame(width: 1, height: 1)

                            Text(isRecordingDictationShortcut ? "音声入力ショートカットを押してください" : store.dictationShortcut.label)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(isRecordingDictationShortcut ? .accentColor : .secondary)
                                .frame(minWidth: 260, alignment: .leading)
                        }

                        Button(isRecordingDictationShortcut ? "入力待ち" : "記録") {
                            toggleDictationShortcutRecording()
                        }

                        Button("macOS設定から読み込む") {
                            store.loadSystemDictationShortcut()
                        }
                    }
                }
            }

            LabeledContent("自動開始の権限") {
                HStack {
                    Text(accessibilityTrusted ? "許可済み" : "未許可")
                        .foregroundColor(accessibilityTrusted ? .secondary : .red)

                    Button("許可を確認") {
                        KeyboardShortcutSender.requestAccessibilityPermissionIfNeeded()
                        accessibilityTrusted = KeyboardShortcutSender.isAccessibilityTrusted
                    }
                }
            }

            LabeledContent("保存先フォルダ") {
                HStack {
                    Text(store.storageFolder.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                    Button("変更") {
                        chooseStorageFolder()
                    }
                }
            }

            LabeledContent("保存形式") {
                Text("Markdown")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 480, minHeight: 220)
        .onDisappear {
            isRecordingShortcut = false
            isRecordingDictationShortcut = false
        }
        .onAppear {
            accessibilityTrusted = KeyboardShortcutSender.isAccessibilityTrusted
        }
    }

    private func chooseStorageFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = store.storageFolder

        if panel.runModal() == .OK, let url = panel.url {
            store.updateStorageFolder(url)
        }
    }

    private func toggleShortcutRecording() {
        if !isRecordingShortcut {
            isRecordingDictationShortcut = false
        }
        isRecordingShortcut.toggle()
    }

    private func toggleDictationShortcutRecording() {
        if !isRecordingDictationShortcut {
            isRecordingShortcut = false
        }
        isRecordingDictationShortcut.toggle()
    }
}
