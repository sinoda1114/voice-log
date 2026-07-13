import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: VoiceLogStore
    @State private var searchText = ""
    @State private var selectedEntryID: VoiceLogEntry.ID?
    @State private var entryPendingDeletion: VoiceLogEntry?

    private var filteredEntries: [VoiceLogEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return store.entries
        }

        return store.entries.filter { entry in
            entry.text.localizedCaseInsensitiveContains(query)
                || Self.dateString(for: entry.createdAt).localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedEntry: VoiceLogEntry? {
        filteredEntries.first { $0.id == selectedEntryID } ?? filteredEntries.first
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Voice Log - 履歴")
                    .font(.headline)
                Spacer()
                TextField("検索", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)
            }
            .padding()

            Divider()

            HSplitView {
                List(filteredEntries, selection: $selectedEntryID) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Self.dateString(for: entry.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(preview(for: entry.text))
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .tag(entry.id)
                }
                .frame(minWidth: 260, idealWidth: 300)

                ScrollView {
                    Text(selectedEntry?.text ?? "履歴を選択してください")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(minWidth: 360)
                .background(Color(nsColor: .textBackgroundColor))
            }

            Divider()

            HStack {
                Button("選択をコピー") {
                    store.copyEntry(selectedEntry)
                }
                .disabled(selectedEntry == nil)

                Button("最新をコピー") {
                    store.copyLatestEntry()
                }
                .disabled(store.entries.isEmpty)

                Button("削除", role: .destructive) {
                    entryPendingDeletion = selectedEntry
                }
                .disabled(selectedEntry == nil)

                Spacer()

                Button("再読み込み") {
                    store.reloadEntries()
                }

                Button("保存フォルダを開く") {
                    store.openStorageFolder()
                }
            }
            .padding()
        }
        .frame(minWidth: 720, minHeight: 420)
        .onAppear {
            store.reloadEntries()
            selectedEntryID = selectedEntryID ?? store.entries.first?.id
        }
        .onChange(of: searchText) { _ in
            selectedEntryID = filteredEntries.first?.id
        }
        .alert("この履歴を削除しますか？", isPresented: Binding(
            get: { entryPendingDeletion != nil },
            set: { if !$0 { entryPendingDeletion = nil } }
        )) {
            Button("キャンセル", role: .cancel) {
                entryPendingDeletion = nil
            }
            Button("削除", role: .destructive) {
                if let entryPendingDeletion {
                    store.delete(entryPendingDeletion)
                    selectedEntryID = store.entries.first?.id
                }
                entryPendingDeletion = nil
            }
        }
    }

    private func preview(for text: String) -> String {
        let singleLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if singleLine.count <= 50 {
            return singleLine
        }
        return "\(singleLine.prefix(50))..."
    }

    private static func dateString(for date: Date) -> String {
        VoiceLogStore.displayDateFormatter.string(from: date)
    }
}
