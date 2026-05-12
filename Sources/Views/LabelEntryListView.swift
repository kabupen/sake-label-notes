import SwiftUI

struct LabelEntryListView: View {
    @StateObject private var store: LabelStore
    @State private var presentingNewEntryEditor = false
    @State private var pendingDeleteEntry: LabelEntry?
    @State private var selectedCategory: BeverageCategoryFilter = .all
    @State private var activeSheet: AppMenuSheet?
    @State private var showingSideMenu = false

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
                                                        Text(entry.title.isEmpty ? "ラベル名未設定" : entry.title)
                                                            .font(.headline)
                                                            .foregroundStyle(entry.title.isEmpty ? .secondary : .primary)
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
                                                                Text(ratingDisplayText(entry.rating))
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
                                                            entry.registeredAt.formatted(date: .abbreviated, time: .shortened),
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

                Color.black.opacity(showingSideMenu ? 0.18 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(showingSideMenu)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showingSideMenu = false
                        }
                    }
                    .animation(.easeOut(duration: 0.22), value: showingSideMenu)

                HStack(spacing: 0) {
                    sideMenu
                        .frame(width: 260)
                        .offset(x: showingSideMenu ? 0 : -260)
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(showingSideMenu)
                .animation(.easeOut(duration: 0.22), value: showingSideMenu)
                .zIndex(1)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingSideMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.black)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if !showingSideMenu {
                        HStack(spacing: 6) {
                            BottleMark()
                                .frame(width: 12, height: 20)
                            Text("サケラベル")
                                .font(.system(size: 17, weight: .black, design: .default))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentingNewEntryEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.black)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $presentingNewEntryEditor) {
                LabelEntryEditorView(mode: .new)
                    .environmentObject(store)
            }
            .sheet(item: $activeSheet) { sheet in
                NavigationStack {
                    switch sheet {
                    case .settings:
                        SettingsView()
                    case .other:
                        OtherInfoView()
                    }
                }
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

    private var sideMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 24)

            Button {
                showingSideMenu = false
                activeSheet = .settings
            } label: {
                Label("設定", systemImage: "gearshape")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Button {
                showingSideMenu = false
                activeSheet = .other
            } label: {
                Label("その他", systemImage: "ellipsis.circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppTheme.background)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, x: 4, y: 0)
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

private enum AppMenuSheet: String, Identifiable {
    case settings
    case other

    var id: String { rawValue }
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

private struct BottleMark: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            Path { path in
                path.move(to: CGPoint(x: width * 0.42, y: 0))
                path.addLine(to: CGPoint(x: width * 0.58, y: 0))
                path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.16))
                path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.24))
                path.addCurve(
                    to: CGPoint(x: width * 0.82, y: height * 0.62),
                    control1: CGPoint(x: width * 0.82, y: height * 0.34),
                    control2: CGPoint(x: width * 0.86, y: height * 0.46)
                )
                path.addCurve(
                    to: CGPoint(x: width * 0.72, y: height),
                    control1: CGPoint(x: width * 0.8, y: height * 0.8),
                    control2: CGPoint(x: width * 0.78, y: height * 0.96)
                )
                path.addLine(to: CGPoint(x: width * 0.28, y: height))
                path.addCurve(
                    to: CGPoint(x: width * 0.18, y: height * 0.62),
                    control1: CGPoint(x: width * 0.22, y: height * 0.96),
                    control2: CGPoint(x: width * 0.2, y: height * 0.8)
                )
                path.addCurve(
                    to: CGPoint(x: width * 0.32, y: height * 0.24),
                    control1: CGPoint(x: width * 0.14, y: height * 0.46),
                    control2: CGPoint(x: width * 0.18, y: height * 0.34)
                )
                path.addLine(to: CGPoint(x: width * 0.38, y: height * 0.16))
                path.closeSubpath()
            }
            .fill(Color.primary)
        }
        .accessibilityHidden(true)
    }
}

#Preview("List") {
    LabelEntryListView(store: .preview)
}
