import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let card = Color.white
    static let accent = Color(red: 0.66, green: 0.22, blue: 0.18)
    static let secondaryText = Color(red: 0.35, green: 0.35, blue: 0.35)
}

struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

