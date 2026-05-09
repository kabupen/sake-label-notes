import UIKit
import Photos
import AVFoundation

enum PhotoLibraryError: Error {
    case unauthorized
    case saveFailed
    case imageFetchFailed
}

struct PhotoLibraryService {
    static func requestCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    static func requestPhotoLibraryAuthorization() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        default:
            return false
        }
    }

    static func saveImageToPhotoLibrary(_ image: UIImage) async throws -> String {
        let allowed = await requestPhotoLibraryAuthorization()
        guard allowed else { throw PhotoLibraryError.unauthorized }

        return try await withCheckedThrowingContinuation { continuation in
            var identifier: String?
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                identifier = request.placeholderForCreatedAsset?.localIdentifier
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard success, let identifier else {
                    continuation.resume(throwing: PhotoLibraryError.saveFailed)
                    return
                }
                continuation.resume(returning: identifier)
            }
        }
    }

    static func fetchUIImage(localIdentifier: String, targetSize: CGSize = CGSize(width: 800, height: 800)) async throws -> UIImage {
        let allowed = await requestPhotoLibraryAuthorization()
        guard allowed else { throw PhotoLibraryError.unauthorized }

        return try await withCheckedThrowingContinuation { continuation in
            let results = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = results.firstObject else {
                continuation.resume(throwing: PhotoLibraryError.imageFetchFailed)
                return
            }

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                guard let image else {
                    continuation.resume(throwing: PhotoLibraryError.imageFetchFailed)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
}
