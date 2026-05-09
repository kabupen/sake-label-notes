import SwiftUI
import UIKit
import Photos

enum PickedPhoto {
    case asset(localIdentifier: String)
    case captured(image: UIImage, metadata: [String: Any])
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (PickedPhoto) -> Void

    @Environment(\.dismiss) private var dismiss

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let asset = info[.phAsset] as? PHAsset {
                parent.onImagePicked(.asset(localIdentifier: asset.localIdentifier))
            } else if let image = info[.originalImage] as? UIImage {
                let metadata = info[.mediaMetadata] as? [String: Any] ?? [:]
                parent.onImagePicked(.captured(image: image, metadata: metadata))
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        picker.view.backgroundColor = .black
        picker.overrideUserInterfaceStyle = .dark

        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.showsCameraControls = true
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
