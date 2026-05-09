import Foundation

struct LabelEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var memo: String
    var imageLocalIdentifier: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        memo: String,
        imageLocalIdentifier: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.imageLocalIdentifier = imageLocalIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension LabelEntry {
    static let previewSamples: [LabelEntry] = [
        LabelEntry(
            title: "新政 No.6",
            memo: "白桃のような香り。口当たりは軽めで余韻がきれい。",
            imageLocalIdentifier: "preview-1",
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 3),
            updatedAt: .now.addingTimeInterval(-60 * 60 * 2)
        ),
        LabelEntry(
            title: "山崎 12年",
            memo: "バニラと樽香。ハイボールでもバランスが良い。",
            imageLocalIdentifier: "preview-2",
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 10),
            updatedAt: .now.addingTimeInterval(-60 * 60 * 24)
        )
    ]
}
