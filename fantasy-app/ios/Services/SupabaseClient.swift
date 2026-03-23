import Foundation

public struct SupabaseConfig {
    public let url: URL
    public let anonKey: String

    public init(urlString: String, anonKey: String) {
        self.url = URL(string: urlString)! // validate on app startup
        self.anonKey = anonKey
    }
}

public final class SupabaseClient {
    private let config: SupabaseConfig
    private let session: URLSession

    public init(config: SupabaseConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    private func request(path: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: config.url.appendingPathComponent(path))
        req.httpMethod = method
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(config.anonKey)", forHTTPHeaderField: "apikey")
        req.addValue(config.anonKey, forHTTPHeaderField: "Authorization")
        req.httpBody = body
        return req
    }

    public func fetch<T: Decodable>(_ path: String, type: T.Type) async throws -> T {
        let request = self.request(path: path)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NSError(domain: "Supabase", code: 1, userInfo: ["data": String(decoding: data, as: UTF8.self)])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func post<T: Decodable>(_ path: String, payload: Encodable, type: T.Type) async throws -> T {
        let body = try JSONEncoder().encode(payload)
        let request = self.request(path: path, method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NSError(domain: "Supabase", code: 2, userInfo: ["data": String(decoding: data, as: UTF8.self)])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
