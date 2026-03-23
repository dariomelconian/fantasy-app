import Foundation

public struct ClaudeConfig {
    public let apiKey: String
    public let apiUrl: URL

    public init(apiKey: String, apiUrlString: String = "https://api.anthropic.com/v1/complete") {
        self.apiKey = apiKey
        self.apiUrl = URL(string: apiUrlString)! // ensure valid URL
    }
}

public final class ClaudeClient {
    private let config: ClaudeConfig
    private let session: URLSession

    public init(config: ClaudeConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func complete(prompt: String, model: String = "claude-3.5-mini", maxTokens: Int = 300) async throws -> String {
        var req = URLRequest(url: config.apiUrl)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "prompt": [["role": "user", "content": prompt]],
            "max_tokens_to_sample": maxTokens,
            "temperature": 0.2
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await session.data(for: req)

        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Claude", code: http.statusCode, userInfo: ["message": message])
        }

        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return decoded.completion
    }
}

private struct ClaudeResponse: Decodable {
    let completion: String

    private enum CodingKeys: String, CodingKey {
        case completion = "completion"
    }
}
