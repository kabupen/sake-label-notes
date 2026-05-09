import SwiftUI
import Foundation

struct PhotoThumbnailView: View {
    let localIdentifier: String
    @State private var image: UIImage?
    private let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isPreview {
                ZStack {
                    Color.gray.opacity(0.12)
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.12)
                    ProgressView()
                }
                .task {
                    await loadImage()
                }
            }
        }
    }

    private func loadImage() async {
        do {
            image = try await PhotoLibraryService.fetchUIImage(localIdentifier: localIdentifier)
        } catch {
            image = nil
        }
    }
}
