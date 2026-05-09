import Foundation

enum BeverageCategory: String, Codable, CaseIterable, Identifiable {
    case sake = "日本酒"
    case wine = "ワイン"
    case whiskey = "ウイスキー"

    var id: String { rawValue }
}

struct LabelEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var memo: String
    var rating: Int
    var category: BeverageCategory
    var imageLocalIdentifier: String
    var backupImageFilename: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        memo: String,
        rating: Int = 0,
        category: BeverageCategory = .sake,
        imageLocalIdentifier: String,
        backupImageFilename: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.rating = rating
        self.category = category
        self.imageLocalIdentifier = imageLocalIdentifier
        self.backupImageFilename = backupImageFilename
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case memo
        case rating
        case category
        case imageLocalIdentifier
        case backupImageFilename
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        memo = try container.decode(String.self, forKey: .memo)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating) ?? 0
        category = try container.decodeIfPresent(BeverageCategory.self, forKey: .category) ?? .sake
        imageLocalIdentifier = try container.decode(String.self, forKey: .imageLocalIdentifier)
        backupImageFilename = try container.decodeIfPresent(String.self, forKey: .backupImageFilename)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

extension LabelEntry {
    static let previewSamples: [LabelEntry] = [
        LabelEntry(
            title: "新政 No.6",
            memo: "白桃のような香り。口当たりは軽めで余韻がきれい。",
            rating: 5,
            category: .sake,
            imageLocalIdentifier: "preview-1",
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 3),
            updatedAt: .now.addingTimeInterval(-60 * 60 * 2)
        ),
        LabelEntry(
            title: "山崎 12年",
            memo: "バニラと樽香。ハイボールでもバランスが良い。",
            rating: 4,
            category: .whiskey,
            imageLocalIdentifier: "preview-2",
            createdAt: .now.addingTimeInterval(-60 * 60 * 24 * 10),
            updatedAt: .now.addingTimeInterval(-60 * 60 * 24)
        )
    ]
}
