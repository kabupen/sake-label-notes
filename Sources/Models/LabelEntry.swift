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
    var registeredAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        memo: String,
        rating: Int = 0,
        category: BeverageCategory = .sake,
        imageLocalIdentifier: String,
        backupImageFilename: String? = nil,
        registeredAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.rating = rating
        self.category = category
        self.imageLocalIdentifier = imageLocalIdentifier
        self.backupImageFilename = backupImageFilename
        self.registeredAt = registeredAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case memo
        case rating
        case category
        case imageLocalIdentifier
        case backupImageFilename
        case registeredAt
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
        let registeredAtValue = try container.decodeIfPresent(Date.self, forKey: .registeredAt)
        let createdAtValue = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        let updatedAtValue = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        registeredAt = registeredAtValue ?? createdAtValue ?? updatedAtValue ?? .now
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(memo, forKey: .memo)
        try container.encode(rating, forKey: .rating)
        try container.encode(category, forKey: .category)
        try container.encode(imageLocalIdentifier, forKey: .imageLocalIdentifier)
        try container.encodeIfPresent(backupImageFilename, forKey: .backupImageFilename)
        try container.encode(registeredAt, forKey: .registeredAt)
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
            registeredAt: .now.addingTimeInterval(-60 * 60 * 24 * 3)
        ),
        LabelEntry(
            title: "山崎 12年",
            memo: "バニラと樽香。ハイボールでもバランスが良い。",
            rating: 4,
            category: .whiskey,
            imageLocalIdentifier: "preview-2",
            registeredAt: .now.addingTimeInterval(-60 * 60 * 24 * 10)
        )
    ]
}
