import SwiftUI

struct AppLaunchView: View {
    @State private var showingSplash = true

    var body: some View {
        ZStack {
            LabelEntryListView()

            if showingSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard showingSplash else { return }
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeOut(duration: 0.25)) {
                showingSplash = false
            }
        }
    }
}

private struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)

                VStack(spacing: 6) {
                    Text("サケラベル")
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundStyle(.primary)

                    Text("ラベル記録をローカルで管理")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    AppLaunchView()
}
