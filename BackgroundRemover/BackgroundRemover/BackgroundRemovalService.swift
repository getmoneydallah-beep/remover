import UIKit

class BackgroundRemovalService {

    static let shared = BackgroundRemovalService()

    private let apiURL = "https://background-removal4.p.rapidapi.com/v1/results?mode=fg-image"
    private let apiKey = "23fae3591emsh5fc120247ac2d0ap1994c9jsnfa6ff3008b3c"
    private let apiHost = "background-removal4.p.rapidapi.com"

    private init() {}

    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw BackgroundRemovalError.invalidImage
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackgroundRemovalError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw BackgroundRemovalError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse JSON response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let results = json?["results"] as? [[String: Any]],
              let firstResult = results.first,
              let entities = firstResult["entities"] as? [[String: Any]],
              let firstEntity = entities.first,
              let base64String = firstEntity["image"] as? String,
              let imageData = Data(base64Encoded: base64String),
              let resultImage = UIImage(data: imageData) else {
            throw BackgroundRemovalError.invalidResponse
        }

        return resultImage
    }
}

enum BackgroundRemovalError: LocalizedError {
    case invalidImage
    case networkError
    case apiError(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image is invalid"
        case .networkError:
            return "Network error occurred"
        case .apiError(let statusCode):
            return "API error: \(statusCode)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
