import UIKit
import Vision
import CoreImage

class BackgroundRemovalService {

    static let shared = BackgroundRemovalService()
    private let context = CIContext()

    private init() {}

    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemovalError.invalidImage
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let result = request.results?.first else {
            throw BackgroundRemovalError.noResultsFound
        }

        let maskedImage = try result.generateMaskedImage(
            ofInstances: result.allInstances,
            from: handler,
            croppedToInstancesExtent: false
        )

        let ciImage = CIImage(cvPixelBuffer: maskedImage)

        guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw BackgroundRemovalError.failedToCreateImage
        }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

enum BackgroundRemovalError: LocalizedError {
    case invalidImage
    case noResultsFound
    case failedToCreateImage

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image is invalid"
        case .noResultsFound:
            return "Could not detect foreground in the image"
        case .failedToCreateImage:
            return "Failed to create the output image"
        }
    }
}
