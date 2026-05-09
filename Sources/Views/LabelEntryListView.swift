import SwiftUI

struct LabelEntryListView: View {
    @StateObject private var store: LabelStore
    @State private var presentingNewEntryEditor = false
    @State private var pendingDeleteEntry: LabelEntry?

    @MainActor
    init(store: LabelStore? = nil) {
        _store = StateObject(wrappedValue: store ?? LabelStore())
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
                        LazyVStack(spacing: 12) {
                            ForEach(store.entries) { entry in
                                NavigationLink {
                                    LabelEntryDetailView(entryID: entry.id)
                                        .environmentObject(store)
                                } label: {
                                    CardContainer {
                                        HStack(spacing: 12) {
                                            PhotoThumbnailView(localIdentifier: entry.imageLocalIdentifier)
                                                .frame(width: 76, height: 76)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(entry.title)
                                                    .font(.headline)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
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
}

#Preview("List") {
    LabelEntryListView(store: .preview)
}
