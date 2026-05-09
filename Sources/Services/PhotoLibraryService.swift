import UIKit
import Photos
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

enum PhotoLibraryError: Error {
    case unauthorized
    case saveFailed
    case imageFetchFailed
    case imageEncodingFailed
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

    static func saveCapturedImageToPhotoLibrary(_ image: UIImage, metadata: [String: Any]) async throws -> String {
        let allowed = await requestPhotoLibraryAuthorization()
        guard allowed else { throw PhotoLibraryError.unauthorized }

        let imageData = try makeImageData(image: image, metadata: metadata)

        return try await withCheckedThrowingContinuation { continuation in
            var identifier: String?
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
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

    private static func makeImageData(image: UIImage, metadata: [String: Any]) throws -> Data {
        let normalizedImage = normalized(image)
        guard let cgImage = normalizedImage.cgImage else {
            throw PhotoLibraryError.imageEncodingFailed
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw PhotoLibraryError.imageEncodingFailed
        }

        var mergedMetadata = metadata
        mergedMetadata[kCGImagePropertyOrientation as String] = CGImagePropertyOrientation(normalizedImage.imageOrientation).rawValue
        CGImageDestinationAddImage(destination, cgImage, mergedMetadata as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw PhotoLibraryError.imageEncodingFailed
        }

        return mutableData as Data
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
