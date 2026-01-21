import Foundation

actor AIService {
    static let shared = AIService()
    
    private init() {}
    
    /// Summarizes the project based on its README and recent changes.
    func summarizeProject(name: String, path: String, changes: String) async -> String {
        // This is a placeholder for where the LLM logic would go.
        // If the user provides an API key, we could call OpenAI/Anthropic/Gemini here.
        
        let readmePath = URL(fileURLWithPath: path).appendingPathComponent("README.md").path
        let hasReadme = FileManager.default.fileExists(atPath: readmePath)
        
        if !hasReadme && changes.isEmpty {
            return "No summary available."
        }
        
        // For now, let's just return a mock "AI" summary to show where it would appear.
        return "AI analysis of \(name): Project appears to focus on \(hasReadme ? "documentation-backed" : "active") development. Recent changes specifically involve: \(changes.isEmpty ? "No uncommitted changes." : changes.prefix(100))."
    }
}
