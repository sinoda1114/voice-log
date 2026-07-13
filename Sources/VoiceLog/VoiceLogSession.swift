import Foundation

@MainActor
final class VoiceLogSession: ObservableObject {
    @Published var text = "" {
        didSet {
            scheduleSave()
        }
    }

    private let createdAt = Date()
    private weak var store: VoiceLogStore?
    private var fileURL: URL?
    private var saveTask: Task<Void, Never>?

    init(store: VoiceLogStore) {
        self.store = store
    }

    deinit {
        saveTask?.cancel()
    }

    func flush() {
        saveTask?.cancel()
        fileURL = store?.save(text: text, createdAt: createdAt, existingFileURL: fileURL)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.flush()
        }
    }
}
