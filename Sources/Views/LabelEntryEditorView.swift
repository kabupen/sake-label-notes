import SwiftUI
import UIKit

enum LabelEntryEditorMode {
    case new
    case edit(LabelEntry)
}

struct LabelEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LabelStore

    let mode: LabelEntryEditorMode

    @State private var title = ""
    @State private var memo = ""
    @State private var selectedImage: UIImage?
    @State private var selectedImageLocalIdentifier: String?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingSourceDialog = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingImagePicker = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? "ラベル編集" : "新規追加"
    }

    private var entryBeingEdited: LabelEntry? {
        if case .edit(let entry) = mode { return entry }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        CardContainer {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ラベル画像")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Group {
                                    if let selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 240)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else if let selectedImageLocalIdentifier {
                                        PhotoThumbnailView(localIdentifier: selectedImageLocalIdentifier)
                                            .scaledToFit()
                                            .frame(maxHeight: 240)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.1))
                                            VStack(spacing: 8) {
                                                Image(systemName: "photo")
                                                    .font(.title2)
                                                Text("画像が未設定です")
                                                    .font(.footnote)
                                            }
                                            .foregroundStyle(.secondary)
                                        }
                                        .frame(height: 180)
                                    }
                                }

                                Button("写真を追加") {
                                    showingSourceDialog = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.accent)
                            }
                        }

                        CardContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ラベル名")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("例: 山崎 12年", text: $title)
                                    .textInputAutocapitalization(.words)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        CardContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メモ")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextEditor(text: $memo)
                                    .frame(minHeight: 150)
                                    .scrollContentBackground(.hidden)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task {
                            await saveEntry()
                        }
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || (selectedImage == nil && selectedImageLocalIdentifier == nil)
                        || isSaving
                    )
                }
            }
            .confirmationDialog("画像を追加", isPresented: $showingSourceDialog) {
                Button("カメラで撮影") {
                    Task {
                        await preparePicker(source: .camera)
                    }
                }
                Button("フォトライブラリから選択") {
                    Task {
                        await preparePicker(source: .photoLibrary)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: pickerSourceType) { image in
                    selectedImage = image
                    errorMessage = nil
                }
            }
            .task {
                await prepareInitialState()
            }
        }
    }

    private func saveEntry() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

            let localIdentifier: String
            if let selectedImage {
                localIdentifier = try await PhotoLibraryService.saveImageToPhotoLibrary(selectedImage)
            } else if let selectedImageLocalIdentifier {
                localIdentifier = selectedImageLocalIdentifier
            } else {
                errorMessage = "画像を追加してください。"
                return
            }

            if let entryBeingEdited {
                store.update(
                    id: entryBeingEdited.id,
                    title: normalizedTitle,
                    memo: memo,
                    imageLocalIdentifier: localIdentifier
                )
            } else {
                store.add(title: normalizedTitle, memo: memo, imageLocalIdentifier: localIdentifier)
            }
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました。写真と権限設定を確認してください。"
        }
    }

    private func prepareInitialState() async {
        guard title.isEmpty, memo.isEmpty else { return }
        if case .edit(let entry) = mode {
            title = entry.title
            memo = entry.memo
            selectedImageLocalIdentifier = entry.imageLocalIdentifier
        }
    }

    private func preparePicker(source: UIImagePickerController.SourceType) async {
        if source == .camera {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                errorMessage = "このデバイスではカメラが利用できません。"
                return
            }
            let cameraAllowed = await PhotoLibraryService.requestCameraAuthorization()
            guard cameraAllowed else {
                errorMessage = "カメラへのアクセスが拒否されています。設定アプリで許可してください。"
                return
            }
        }

        let libraryAllowed = await PhotoLibraryService.requestPhotoLibraryAuthorization()
        guard libraryAllowed else {
            errorMessage = "写真ライブラリへのアクセスが必要です。設定アプリで許可してください。"
            return
        }

        pickerSourceType = source
        showingImagePicker = true
    }
}

#Preview("Editor New") {
    LabelEntryEditorView(mode: .new)
        .environmentObject(LabelStore(previewEntries: LabelEntry.previewSamples))
}

#Preview("Editor Edit") {
    LabelEntryEditorView(mode: .edit(LabelEntry.previewSamples[0]))
        .environmentObject(LabelStore(previewEntries: LabelEntry.previewSamples))
}
