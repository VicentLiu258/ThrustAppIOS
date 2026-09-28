import Foundation

struct JumpSearchResponse: Codable {
    let code: Int
    let msg: String?
    let data: JumpData?
}

struct JumpData: Codable {
    let url: String?
    let resident: Int?
}

@MainActor
final class JumpSearchService {
    static let shared = JumpSearchService()

    private init() {}

    /// Requests the jump configuration API with the specified keyword.
    /// Returns the target URL string if code == 1 and url is valid, or nil otherwise.
    func fetchJumpUrl(keyword: String) async -> String? {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard let encodedKeyword = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.thrustwealth.com/index/jump/search?keyword=\(encodedKeyword)") else {
            return nil
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 12)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let decoded = try JSONDecoder().decode(JumpSearchResponse.self, from: data)
            if decoded.code == 1,
               let targetUrl = decoded.data?.url?.trimmingCharacters(in: .whitespacesAndNewlines),
               !targetUrl.isEmpty,
               targetUrl.hasPrefix("http://") || targetUrl.hasPrefix("https://") {
                return targetUrl
            }
        } catch {
            print("[JumpSearchService] Error requesting jump search: \(error)")
        }

        return nil
    }
}
