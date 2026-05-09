import SwiftUI

struct LabelEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LabelStore

    let entryID: UUID
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            if let entry = store.entries.first(where: { $0.id == entryID }) {
                ScrollView {
                    VStack(spacing: 12) {
                        CardContainer {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("写真")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                PhotoThumbnailView(
                                    localIdentifier: entry.imageLocalIdentifier,
                                    backupImageFilename: entry.backupImageFilename
                                )
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        CardContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ラベル名")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.title)
                                    .font(.title3.weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        CardContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("登録情報")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        CardContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メモ")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.memo.isEmpty ? "メモはありません" : entry.memo)
                                    .foregroundStyle(entry.memo.isEmpty ? .secondary : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        CardContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("日時")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Label("作成: \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "calendar")
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Label("更新: \(entry.updatedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock.arrow.circlepath")
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("削除")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            } else {
                ContentUnavailableView("エントリが見つかりません", systemImage: "exclamationmark.triangle")
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let currentEntry = store.entries.first(where: { $0.id == entryID }) {
                LabelEntryEditorView(mode: .edit(currentEntry))
                    .environmentObject(store)
            }
        }
        .alert("このラベルを削除しますか？", isPresented: $showingDeleteConfirmation) {
            if let entry = store.entries.first(where: { $0.id == entryID }) {
                Button("削除", role: .destructive) {
                    store.deleteEntry(entry)
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
        .navigationTitle("詳細")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.entries.contains(where: { $0.id == entryID }) {
                    Button("編集") {
                        showingEditor = true
                    }
                }
            }
        }
    }
}

#Preview("Detail") {
    NavigationStack {
        LabelEntryDetailView(entryID: LabelEntry.previewSamples[0].id)
            .environmentObject(LabelStore(previewEntries: LabelEntry.previewSamples))
    }
}
