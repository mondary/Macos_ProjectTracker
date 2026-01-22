import Foundation

actor AIService {
    static let shared = AIService()
    
    private init() {}
    
    /// Summarizes the project based on its README and recent changes.
    func summarizeProject(name: String, path: String, changes: String) async -> String {
        let defaults = UserDefaults.standard
        let openAIKey = defaults.string(forKey: "openAIKey") ?? ""
        let geminiKey = defaults.string(forKey: "geminiKey") ?? ""
        let openRouterKey = defaults.string(forKey: "openRouterKey") ?? ""
        
        var provider = "Mock AI"
        if !openAIKey.isEmpty {
            provider = "OpenAI"
        } else if !geminiKey.isEmpty {
            provider = "Gemini"
        } else if !openRouterKey.isEmpty {
            provider = "OpenRouter"
        }
        
        let readmePath = URL(fileURLWithPath: path).appendingPathComponent("README.md").path
        let hasReadme = FileManager.default.fileExists(atPath: readmePath)
        
        if !hasReadme && changes.isEmpty {
            return "[\(provider)] No summary available."
        }
        
        // Simulating provider specific response
        return "[\(provider)] \(name): \(hasReadme ? "Documentation-rich" : "Active") project. Changes: \(changes.isEmpty ? "Clean" : "Modified")."
    }
}
