import UIKit

class BackgroundRemovalService {

    static let shared = BackgroundRemovalService()

    private let apiURL = "https://api.remove.bg/v1.0/removebg"
    private let apiKey = "yJCxfkwcTGbVW7bqksJNFMmS"

    private init() {}

    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw BackgroundRemovalError.invalidImage
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add size parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
        body.append("auto\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackgroundRemovalError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = errorJson["errors"] as? [[String: Any]],
               let firstError = errors.first,
               let title = firstError["title"] as? String {
                throw BackgroundRemovalError.apiErrorMessage(title)
            }
            throw BackgroundRemovalError.apiError(statusCode: httpResponse.statusCode)
        }

        // Response is the PNG image directly
        guard let resultImage = UIImage(data: data) else {
            throw BackgroundRemovalError.invalidResponse
        }

        return resultImage
    }
}

enum BackgroundRemovalError: LocalizedError {
    case invalidImage
    case networkError
    case apiError(statusCode: Int)
    case apiErrorMessage(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "الصورة المحددة غير صالحة"
        case .networkError:
            return "حدث خطأ في الاتصال"
        case .apiError(let statusCode):
            return "خطأ في الخدمة: \(statusCode)"
        case .apiErrorMessage(let message):
            return message
        case .invalidResponse:
            return "استجابة غير صالحة من الخادم"
        }
    }
}
