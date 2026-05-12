import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private var versionText: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            List {
                Section("アプリ情報") {
                    HStack {
                        Text("アプリバージョン")
                        Spacer()
                        Text(versionText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        }
        .navigationTitle("設定")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

struct OtherInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            List {
                NavigationLink("利用規約") {
                    LegalDocumentView(
                        title: "利用規約",
                        sections: [
                            LegalSection(
                                heading: "1. 利用範囲",
                                body: "本アプリは、ユーザー自身がお酒ラベルの写真、メモ、評価を端末内で記録・管理する目的で利用します。"
                            ),
                            LegalSection(
                                heading: "2. 保存データ",
                                body: "登録データは端末内に保存されます。ユーザーは、自身の責任で保存内容を管理し、必要に応じてバックアップを行うものとします。"
                            ),
                            LegalSection(
                                heading: "3. 禁止事項",
                                body: "法令違反、公序良俗違反、第三者の権利侵害、またはアプリの正常な動作を妨げる行為を禁止します。"
                            ),
                            LegalSection(
                                heading: "4. 免責",
                                body: "本アプリの利用によって生じたデータ損失、端末障害、その他の損害について、開発者は故意または重過失がある場合を除き責任を負いません。"
                            )
                        ]
                    )
                }

                NavigationLink("プライバシーポリシー") {
                    LegalDocumentView(
                        title: "プライバシーポリシー",
                        sections: [
                            LegalSection(
                                heading: "1. 取得する情報",
                                body: "本アプリは、ラベル画像、メモ、評価、登録日時など、ユーザーが入力または選択した情報を端末内に保存します。"
                            ),
                            LegalSection(
                                heading: "2. カメラ・写真へのアクセス",
                                body: "カメラ撮影およびフォトライブラリからの画像選択のために、端末のカメラおよび写真ライブラリへアクセスします。"
                            ),
                            LegalSection(
                                heading: "3. 外部送信",
                                body: "本アプリはクラウド同期や外部サーバー送信を行わず、保存データを外部へ送信しません。"
                            ),
                            LegalSection(
                                heading: "4. データ削除",
                                body: "ユーザーはアプリ内の削除操作により登録データを削除できます。端末からアプリを削除すると、アプリ内保存データも削除されます。"
                            )
                        ]
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        }
        .navigationTitle("その他")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private struct LegalDocumentView: View {
    let title: String
    let sections: [LegalSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(sections) { section in
                    CardContainer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.heading)
                                .font(.headline)
                            Text(section.body)
                                .font(.body)
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegalSection: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}
