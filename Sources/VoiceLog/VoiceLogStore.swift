import AppKit
import Foundation

@MainActor
final class VoiceLogStore: ObservableObject {
    @Published private(set) var entries: [VoiceLogEntry] = []
    @Published var storageFolder: URL
    @Published var captureShortcut: CaptureShortcut {
        didSet {
            defaults.set(captureShortcut.storedValue, forKey: Self.shortcutKey)
        }
    }
    @Published var dictationShortcut: CaptureShortcut {
        didSet {
            defaults.set(dictationShortcut.storedValue, forKey: Self.dictationShortcutKey)
        }
    }
    @Published var autoStartsDictation: Bool {
        didSet {
            defaults.set(autoStartsDictation, forKey: Self.autoStartsDictationKey)
        }
    }

    private let defaults: UserDefaults
    private static let storageKey = "storageFolderBookmarkPath"
    private static let formatKey = "storageFormat"
    private static let shortcutKey = "launchShortcut"
    private static let dictationShortcutKey = "dictationShortcut"
    private static let autoStartsDictationKey = "autoStartsDictation"
    private static let menuBarIconKey = "menuBarIcon"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        Self.registerDefaultSettings(defaults: defaults)
        captureShortcut = CaptureShortcut.fromSavedValue(defaults.string(forKey: Self.shortcutKey))
        let systemDictationShortcut = SystemDictationShortcutReader.readFromDefaults()
        dictationShortcut = CaptureShortcut.fromSavedValue(
            defaults.string(forKey: Self.dictationShortcutKey),
            default: systemDictationShortcut ?? .f5
        )
        autoStartsDictation = defaults.bool(forKey: Self.autoStartsDictationKey)

        if let savedPath = defaults.string(forKey: Self.storageKey), !savedPath.isEmpty {
            storageFolder = URL(fileURLWithPath: NSString(string: savedPath).expandingTildeInPath)
        } else {
            storageFolder = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents", isDirectory: true)
                .appendingPathComponent("VoiceLog", isDirectory: true)
        }

        ensureStorageFolder()
        reloadEntries()
    }

    func ensureStorageFolder() {
        do {
            try FileManager.default.createDirectory(
                at: storageFolder,
                withIntermediateDirectories: true
            )
        } catch {
            NSLog("Failed to create storage folder: \(error.localizedDescription)")
        }
    }

    func updateStorageFolder(_ url: URL) {
        storageFolder = url
        defaults.set(url.path, forKey: Self.storageKey)
        ensureStorageFolder()
        reloadEntries()
    }

    func loadSystemDictationShortcut() {
        if let shortcut = SystemDictationShortcutReader.readFromDefaults() {
            dictationShortcut = shortcut
        }
    }

    func reloadEntries() {
        ensureStorageFolder()

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: storageFolder,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            entries = fileURLs
                .filter { $0.pathExtension.lowercased() == "md" }
                .compactMap(loadEntry)
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            entries = []
            NSLog("Failed to load entries: \(error.localizedDescription)")
        }
    }

    func makeSession() -> VoiceLogSession {
        VoiceLogSession(store: self)
    }

    func save(text: String, createdAt: Date, existingFileURL: URL?) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if let existingFileURL, FileManager.default.fileExists(atPath: existingFileURL.path) {
                try? FileManager.default.removeItem(at: existingFileURL)
                reloadEntries()
            }
            return nil
        }

        ensureStorageFolder()
        let fileURL = existingFileURL ?? storageFolder.appendingPathComponent(Self.fileName(for: createdAt))
        let markdown = Self.markdown(for: text, createdAt: createdAt)

        do {
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            reloadEntries()
            return fileURL
        } catch {
            NSLog("Failed to save entry: \(error.localizedDescription)")
            return existingFileURL
        }
    }

    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func copyEntry(_ entry: VoiceLogEntry?) {
        guard let entry else { return }
        copy(entry.text)
    }

    func copyLatestEntry() {
        copyEntry(entries.first)
    }

    func delete(_ entry: VoiceLogEntry) {
        do {
            try FileManager.default.trashItem(at: entry.fileURL, resultingItemURL: nil)
        } catch {
            do {
                try FileManager.default.removeItem(at: entry.fileURL)
            } catch {
                NSLog("Failed to delete entry: \(error.localizedDescription)")
            }
        }
        reloadEntries()
    }

    func openStorageFolder() {
        ensureStorageFolder()
        NSWorkspace.shared.open(storageFolder)
    }

    private static func registerDefaultSettings(defaults: UserDefaults) {
        defaults.register(defaults: [
            Self.formatKey: "Markdown",
            Self.shortcutKey: CaptureShortcut.optionF5.storedValue,
            Self.dictationShortcutKey: CaptureShortcut.f5.storedValue,
            Self.autoStartsDictationKey: true,
            Self.menuBarIconKey: "text.bubble"
        ])
    }

    private func loadEntry(from url: URL) -> VoiceLogEntry? {
        guard let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        let createdAt = parseHeaderDate(from: markdown)
            ?? values?.creationDate
            ?? values?.contentModificationDate
            ?? Date.distantPast
        let updatedAt = values?.contentModificationDate ?? createdAt
        let text = stripMarkdownHeader(from: markdown)

        return VoiceLogEntry(
            id: stableID(for: url),
            createdAt: createdAt,
            updatedAt: updatedAt,
            text: text,
            fileURL: url
        )
    }

    private func parseHeaderDate(from markdown: String) -> Date? {
        guard let firstLine = markdown.split(separator: "\n", maxSplits: 1).first else {
            return nil
        }

        let rawDate = firstLine.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        return Self.displayDateFormatter.date(from: rawDate)
    }

    private func stripMarkdownHeader(from markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        if lines.first?.hasPrefix("# ") == true {
            return lines.dropFirst().drop { $0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: "\n")
        }
        return markdown
    }

    private func stableID(for url: URL) -> UUID {
        let uuidBytes = Array(url.path.utf8).reduce(into: [UInt8](repeating: 0, count: 16)) { bytes, value in
            let index = Int(value) % bytes.count
            bytes[index] = bytes[index] &+ value
        }
        return uuidBytes.withUnsafeBufferPointer { buffer in
            UUID(uuid: (
                buffer[0], buffer[1], buffer[2], buffer[3],
                buffer[4], buffer[5], buffer[6], buffer[7],
                buffer[8], buffer[9], buffer[10], buffer[11],
                buffer[12], buffer[13], buffer[14], buffer[15]
            ))
        }
    }

    private static func markdown(for text: String, createdAt: Date) -> String {
        "# \(displayDateFormatter.string(from: createdAt))\n\n\(text)\n"
    }

    private static func fileName(for date: Date) -> String {
        "\(fileDateFormatter.string(from: date)).md"
    }

    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }()
}
