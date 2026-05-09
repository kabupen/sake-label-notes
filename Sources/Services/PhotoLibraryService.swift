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
    case backupSaveFailed
    case backupLoadFailed
}

struct CapturedPhotoSaveResult {
    let localIdentifier: String
    let backupImageFilename: String
}

struct PhotoLibraryService {
    private static let captureImageSize = CGSize(width: 2268, height: 4032)
    private static let backupMaxPixelSize: CGFloat = 960

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

    static func saveCapturedImageAssets(_ image: UIImage, metadata: [String: Any]) async throws -> CapturedPhotoSaveResult {
        let processedImage = processedCapturedImage(image)
        let localIdentifier = try await saveCapturedImageToPhotoLibrary(processedImage, metadata: metadata)
        let backupImageFilename = try saveBackupImage(processedImage)
        return CapturedPhotoSaveResult(
            localIdentifier: localIdentifier,
            backupImageFilename: backupImageFilename
        )
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

    static func loadBackupImage(filename: String) throws -> UIImage {
        let fileURL = backupDirectoryURL().appendingPathComponent(filename)
        let data = try Data(contentsOf: fileURL)
        guard let image = UIImage(data: data) else {
            throw PhotoLibraryError.backupLoadFailed
        }
        return image
    }

    static func deleteBackupImage(filename: String?) {
        guard let filename else { return }
        let fileURL = backupDirectoryURL().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
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
        mergedMetadata[kCGImagePropertyOrientation as String] = CGImagePropertyOrientation.up.rawValue
        mergedMetadata[kCGImagePropertyPixelWidth as String] = Int(normalizedImage.size.width)
        mergedMetadata[kCGImagePropertyPixelHeight as String] = Int(normalizedImage.size.height)
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

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1
        let renderSize = CGSize(
            width: image.cgImage.map { CGFloat($0.width) } ?? image.size.width,
            height: image.cgImage.map { CGFloat($0.height) } ?? image.size.height
        )
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: rendererFormat)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: renderSize))
        }
    }

    private static func processedCapturedImage(_ image: UIImage) -> UIImage {
        let normalizedImage = normalized(image)
        let croppedImage = croppedToPortraitNineSixteen(normalizedImage)
        return resizedImage(croppedImage, to: captureImageSize)
    }

    private static func croppedToPortraitNineSixteen(_ image: UIImage) -> UIImage {
        let targetRatio = captureImageSize.width / captureImageSize.height
        let sourceSize = image.size
        let sourceRatio = sourceSize.width / sourceSize.height

        let cropRect: CGRect
        if sourceRatio > targetRatio {
            let cropWidth = sourceSize.height * targetRatio
            cropRect = CGRect(
                x: (sourceSize.width - cropWidth) / 2,
                y: 0,
                width: cropWidth,
                height: sourceSize.height
            )
        } else {
            let cropHeight = sourceSize.width / targetRatio
            cropRect = CGRect(
                x: 0,
                y: (sourceSize.height - cropHeight) / 2,
                width: sourceSize.width,
                height: cropHeight
            )
        }

        guard let cgImage = image.cgImage?.cropping(to: cropRect.integral) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }

    private static func resizedImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private static func saveBackupImage(_ image: UIImage) throws -> String {
        let backupImage = downscaledBackupImage(image)
        guard let data = backupImage.jpegData(compressionQuality: 0.82) else {
            throw PhotoLibraryError.backupSaveFailed
        }

        let filename = "\(UUID().uuidString).jpg"
        let fileURL = backupDirectoryURL().appendingPathComponent(filename)
        do {
            try FileManager.default.createDirectory(at: backupDirectoryURL(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            return filename
        } catch {
            throw PhotoLibraryError.backupSaveFailed
        }
    }

    private static func downscaledBackupImage(_ image: UIImage) -> UIImage {
        let sourceSize = image.size
        let longerEdge = max(sourceSize.width, sourceSize.height)
        guard longerEdge > backupMaxPixelSize else {
            return image
        }

        let scale = backupMaxPixelSize / longerEdge
        let targetSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        return resizedImage(image, to: targetSize)
    }

    private static func backupDirectoryURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("SakeLabelNotes/ImageBackups", isDirectory: true)
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
