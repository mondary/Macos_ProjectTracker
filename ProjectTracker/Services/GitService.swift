import Foundation

actor GitService {
    static let shared = GitService()
    
    private init() {}
    
    func scanDirectory(at path: String, excluding excludedSubfolders: [String] = []) async -> [Project] {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)
        let excludedSet = Set(
            excludedSubfolders.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        )
        
        // Collect URLs first because NSDirectoryEnumerator is not Sendable/Async-safe
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return []
        }
        
        var gitFolders: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            let relativePath = fileURL.path.replacingOccurrences(of: url.path, with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !relativePath.isEmpty {
                let components = relativePath.split(separator: "/").map { String($0).lowercased() }
                if components.contains(where: { excludedSet.contains($0) }) {
                    enumerator.skipDescendants()
                    continue
                }
            }

            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fileURL.appendingPathComponent(".git").path, isDirectory: &isDirectory), isDirectory.boolValue {
                gitFolders.append(fileURL)
                enumerator.skipDescendants()
            }
        }
        
        var projects: [Project] = []
        for folderURL in gitFolders {
            if let project = await getProjectStatus(at: folderURL) {
                projects.append(project)
            }
        }
        
        return projects
    }
    
    private func getProjectStatus(at url: URL) async -> Project? {
        let path = url.path
        let name = url.lastPathComponent
        
        async let branch = runGitCommand(args: ["rev-parse", "--abbrev-ref", "HEAD"], at: path)
        async let status = runGitCommand(args: ["status", "--porcelain"], at: path)
        async let counts = getAheadBehindCount(at: path)
        async let remote = runGitCommand(args: ["remote", "get-url", "origin"], at: path)
        
        let (resolvedBranch, resolvedStatus, resolvedCounts, resolvedRemote) = await (branch, status, counts, remote)
        let trimmedRemote = resolvedRemote.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let summary = await AIService.shared.summarizeProject(
            name: name,
            path: path,
            changes: resolvedStatus
        )
        let description = readReadmeDescription(at: path)
        let hasReadme = FileManager.default.fileExists(atPath: URL(fileURLWithPath: path).appendingPathComponent("README.md").path)
        let hasIcon = FileManager.default.fileExists(atPath: URL(fileURLWithPath: path).appendingPathComponent("icon.png").path)
        
        return Project(
            name: name,
            path: path,
            lastUpdated: Date(),
            isDirty: !resolvedStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            aheadCount: resolvedCounts.ahead,
            behindCount: resolvedCounts.behind,
            branch: resolvedBranch.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary,
            remoteURL: trimmedRemote.isEmpty ? nil : trimmedRemote,
            description: description,
            hasIcon: hasIcon,
            hasReadme: hasReadme
        )
    }
    
    private func getAheadBehindCount(at path: String) async -> (ahead: Int, behind: Int) {
        let output = await runGitCommand(args: ["rev-list", "--left-right", "--count", "HEAD...@{u}"], at: path)
        let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t")
        if parts.count == 2, let ahead = Int(parts[0]), let behind = Int(parts[1]) {
            return (ahead, behind)
        }
        return (0, 0)
    }
    
    private func runGitCommand(args: [String], at path: String) async -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path] + args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private func readReadmeDescription(at path: String) -> String? {
        let readmeURL = URL(fileURLWithPath: path).appendingPathComponent("README.md")
        guard let data = try? Data(contentsOf: readmeURL),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("#") {
                let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "# ").union(.whitespaces))
                if !cleaned.isEmpty { return cleaned }
                continue
            }
            return String(trimmed)
        }
        return nil
    }
}
