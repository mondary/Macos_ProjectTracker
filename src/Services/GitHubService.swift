import Foundation

struct GitHubRepo: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let htmlURL: String
    let isPrivate: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case htmlURL = "html_url"
        case isPrivate = "private"
    }
}

actor GitHubService {
    static let shared = GitHubService()
    
    private init() {}
    
    func fetchRepos(username: String, token: String?) async throws -> [GitHubRepo] {
        var repos: [GitHubRepo] = []
        var page = 1
        
        while true {
            let urlString = "https://api.github.com/users/\(username)/repos?per_page=100&page=\(page)"
            guard let url = URL(string: urlString) else { break }
            
            var request = URLRequest(url: url)
            request.addValue("ProjectTracker", forHTTPHeaderField: "User-Agent")
            if let token, !token.isEmpty {
                request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                break
            }
            
            let pageRepos = try JSONDecoder().decode([GitHubRepo].self, from: data)
            repos.append(contentsOf: pageRepos)
            if pageRepos.count < 100 { break }
            page += 1
        }
        
        return repos
    }
}
