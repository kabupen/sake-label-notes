import Foundation

@MainActor
final class LabelStore: ObservableObject {
    @Published private(set) var entries: [LabelEntry] = []

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = directory.appendingPathComponent("SakeLabelNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        self.fileURL = appDirectory.appendingPathComponent("entries.json")
        load()
    }

    init(previewEntries: [LabelEntry]) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = directory.appendingPathComponent("SakeLabelNotes", isDirectory: true)
        self.fileURL = appDirectory.appendingPathComponent("preview-entries.json")
        self.entries = previewEntries.sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    func loadEntries() -> [LabelEntry] {
        entries
    }

    func saveEntry(_ entry: LabelEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entry
            updated.updatedAt = .now
            entries[index] = updated
        } else {
            entries.insert(entry, at: 0)
        }
        entries.sort(by: { $0.updatedAt > $1.updatedAt })
        save()
    }

    func deleteEntry(_ entry: LabelEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func resetStore() {
        entries = []
        save()
    }

    func add(
        title: String,
        memo: String,
        rating: Int,
        category: BeverageCategory,
        imageLocalIdentifier: String
    ) {
        let entry = LabelEntry(
            title: title,
            memo: memo,
            rating: rating,
            category: category,
            imageLocalIdentifier: imageLocalIdentifier
        )
        saveEntry(entry)
    }

    func update(
        id: UUID,
        title: String,
        memo: String,
        rating: Int,
        category: BeverageCategory,
        imageLocalIdentifier: String? = nil
    ) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].title = title
        entries[index].memo = memo
        entries[index].rating = rating
        entries[index].category = category
        if let imageLocalIdentifier {
            entries[index].imageLocalIdentifier = imageLocalIdentifier
        }
        entries[index].updatedAt = .now
        entries.sort(by: { $0.updatedAt > $1.updatedAt })
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([LabelEntry].self, from: data)
            entries = decoded.sorted(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            entries = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }
}

extension LabelStore {
    static let preview: LabelStore = {
        LabelStore(previewEntries: LabelEntry.previewSamples)
    }()
}
