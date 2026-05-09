import SwiftUI

struct LabelEntryListView: View {
    @StateObject private var store: LabelStore
    @State private var presentingNewEntryEditor = false
    @State private var pendingDeleteEntry: LabelEntry?
    @State private var selectedCategory: BeverageCategoryFilter = .all

    @MainActor
    init(store: LabelStore? = nil) {
        _store = StateObject(wrappedValue: store ?? LabelStore())
    }

    private var filteredEntries: [LabelEntry] {
        switch selectedCategory {
        case .all:
            return store.entries
        case .category(let category):
            return store.entries.filter { $0.category == category }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                if store.entries.isEmpty {
                    ContentUnavailableView {
                        Label("まだラベルがありません", systemImage: "wineglass")
                    } description: {
                        Text("右上の + から写真付きメモを追加できます。")
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            filterBar

                            if filteredEntries.isEmpty {
                                ContentUnavailableView {
                                    Label("該当するラベルがありません", systemImage: "line.3.horizontal.decrease.circle")
                                } description: {
                                    Text("別のお酒ラベルを選ぶと、保存済みエントリを表示できます。")
                                }
                                .padding(.top, 24)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredEntries) { entry in
                                        NavigationLink {
                                            LabelEntryDetailView(entryID: entry.id)
                                                .environmentObject(store)
                                        } label: {
                                            CardContainer {
                                                HStack(spacing: 12) {
                                                    PhotoThumbnailView(
                                                        localIdentifier: entry.imageLocalIdentifier,
                                                        backupImageFilename: entry.backupImageFilename
                                                    )
                                                        .frame(width: 76, height: 76)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text(entry.title)
                                                            .font(.headline)
                                                            .foregroundStyle(.primary)
                                                            .lineLimit(1)
                                                        HStack(spacing: 8) {
                                                            Text(entry.category.rawValue)
                                                                .font(.caption.weight(.medium))
                                                                .foregroundStyle(AppTheme.accent)
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 4)
                                                                .background(AppTheme.accent.opacity(0.12))
                                                                .clipShape(Capsule())

                                                            if entry.rating > 0 {
                                                                Text(String(repeating: "★", count: entry.rating))
                                                                    .font(.caption)
                                                                    .foregroundStyle(.orange)
                                                            } else {
                                                                Text("未評価")
                                                                    .font(.caption)
                                                                    .foregroundStyle(.secondary)
                                                            }
                                                        }
                                                        Text(entry.memo.isEmpty ? "メモなし" : entry.memo)
                                                            .font(.subheadline)
                                                            .foregroundStyle(AppTheme.secondaryText)
                                                            .lineLimit(2)
                                                        Label(
                                                            entry.updatedAt.formatted(date: .abbreviated, time: .shortened),
                                                            systemImage: "clock"
                                                        )
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                    }
                                                    Spacer(minLength: 0)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                pendingDeleteEntry = entry
                                            } label: {
                                                Label("削除", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Sake Label Notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Local First")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentingNewEntryEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $presentingNewEntryEditor) {
                LabelEntryEditorView(mode: .new)
                    .environmentObject(store)
            }
            .alert("このラベルを削除しますか？", isPresented: deleteAlertBinding) {
                Button("削除", role: .destructive) {
                    if let pendingDeleteEntry {
                        store.deleteEntry(pendingDeleteEntry)
                    }
                    pendingDeleteEntry = nil
                }
                Button("キャンセル", role: .cancel) {
                    pendingDeleteEntry = nil
                }
            } message: {
                Text("この操作は取り消せません。")
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteEntry != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteEntry = nil
                }
            }
        )
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BeverageCategoryFilter.allCases) { filter in
                    Button {
                        selectedCategory = filter
                    } label: {
                        Text(filter.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(selectedCategory == filter ? Color.white : AppTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == filter ? AppTheme.accent : AppTheme.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum BeverageCategoryFilter: CaseIterable, Identifiable, Equatable {
    case all
    case category(BeverageCategory)

    static var allCases: [BeverageCategoryFilter] {
        [.all] + BeverageCategory.allCases.map(Self.category)
    }

    var id: String {
        switch self {
        case .all:
            return "all"
        case .category(let category):
            return category.rawValue
        }
    }

    var title: String {
        switch self {
        case .all:
            return "すべて"
        case .category(let category):
            return category.rawValue
        }
    }
}

#Preview("List") {
    LabelEntryListView(store: .preview)
}
