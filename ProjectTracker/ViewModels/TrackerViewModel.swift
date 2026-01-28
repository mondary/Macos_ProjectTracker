import Foundation
import SwiftUI

@MainActor
class TrackerViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isScanning = false
    @Published var lastScanDate: Date?
    @Published var searchText: String = ""
    
    @AppStorage("scanPath") var scanPath: String = NSString(string: "~/Documents/GitHub").expandingTildeInPath
    @AppStorage("openAIKey") var openAIKey: String = ""
    @AppStorage("geminiKey") var geminiKey: String = ""
    @AppStorage("openRouterKey") var openRouterKey: String = ""
    @AppStorage("cachedProjects") private var cachedProjectsData: Data = Data()
    @AppStorage("cachedLastScan") private var cachedLastScan: Double = 0
    @AppStorage("cachedScanLog") private var cachedScanLog: String = ""
    @Published var lastScanLog: String = ""
    @AppStorage("scanIntervalMinutes") var scanIntervalMinutes: Int = 60
    @AppStorage("excludedSubfolders") private var excludedSubfolders: String = ""
    @AppStorage("githubUsername") var githubUsername: String = "mondary"
    @AppStorage("githubUseAuth") var githubUseAuth: Bool = false
    @AppStorage("githubToken") var githubToken: String = ""
    @AppStorage("cachedGithubRepos") private var cachedGithubReposData: Data = Data()
    @Published var githubRepos: [GitHubRepo] = []
    @AppStorage("reportPath") var reportPath: String = NSString(string: "~/Documents/ProjectTracker/report.html").expandingTildeInPath
    @AppStorage("reportAutoGenerate") var reportAutoGenerate: Bool = true
    @AppStorage("reportAutoOpen") var reportAutoOpen: Bool = true

    var excludedSubfolderList: [String] {
        excludedSubfolders
            .split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var timer: Timer?
    
    init() {
        loadCachedProjects()
        loadCachedLastScan()
        loadCachedScanLog()
        loadCachedGitHubRepos()
        startTimer()
        Task {
            await scan()
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        let interval = max(1, scanIntervalMinutes) * 60
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { _ in
            Task { @MainActor in
                await self.scan()
            }
        }
    }
    
    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        
        let start = Date()
        let path = scanPath
        let excluded = excludedSubfolderList
        let scannedProjects = await Task.detached {
            await GitService.shared.scanDirectory(at: path, excluding: excluded)
        }.value
        
        self.projects = scannedProjects.sorted { p1, p2 in
            if p1.hasChanges != p2.hasChanges {
                return p1.hasChanges
            }
            return p1.name < p2.name
        }
        
        lastScanDate = Date()
        saveCachedLastScan()
        updateScanLog(start: start, end: lastScanDate ?? Date(), path: path)
        saveCachedProjects()
        isScanning = false
        
        Task {
            await fetchGitHubRepos()
        }
        
        if reportAutoGenerate {
            await ReportService.shared.generateReport(
                projects: projects,
                outputPath: reportPath,
                scanDate: lastScanDate ?? Date()
            )
            if reportAutoOpen {
                await ReportService.shared.openReport(at: reportPath)
            }
        }
    }

    private func loadCachedProjects() {
        guard !cachedProjectsData.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode([Project].self, from: cachedProjectsData)
            self.projects = decoded
        } catch {
            // Ignore cache failures to avoid blocking startup
        }
    }

    private func saveCachedProjects() {
        do {
            let encoded = try JSONEncoder().encode(projects)
            cachedProjectsData = encoded
        } catch {
            // Ignore cache failures to avoid blocking scanning
        }
    }

    private func loadCachedLastScan() {
        guard cachedLastScan > 0 else { return }
        lastScanDate = Date(timeIntervalSince1970: cachedLastScan)
    }

    private func saveCachedLastScan() {
        guard let lastScanDate else { return }
        cachedLastScan = lastScanDate.timeIntervalSince1970
    }

    private func loadCachedScanLog() {
        lastScanLog = cachedScanLog
    }

    private func updateScanLog(start: Date, end: Date, path: String) {
        let duration = end.timeIntervalSince(start)
        let total = projects.count
        let dirty = projects.filter { $0.isDirty }.count
        let ahead = projects.filter { $0.aheadCount > 0 }.count
        let behind = projects.filter { $0.behindCount > 0 }.count
        let clean = projects.filter { !$0.hasChanges }.count
        let linked = projects.filter { $0.isLinkedToGitHub }.count
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        
        let log = """
        Scan: \(formatter.string(from: end))
        Path: \(path)
        Duration: \(String(format: "%.2fs", duration))
        Projects: \(total)
        Clean: \(clean)
        Dirty: \(dirty)
        Ahead: \(ahead)
        Behind: \(behind)
        GitHub linked: \(linked)
        """
        
        lastScanLog = log
        cachedScanLog = log
    }

    private func loadCachedGitHubRepos() {
        guard !cachedGithubReposData.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode([GitHubRepo].self, from: cachedGithubReposData)
            githubRepos = decoded
        } catch {
            // Ignore cache failures
        }
    }

    private func saveCachedGitHubRepos() {
        do {
            let encoded = try JSONEncoder().encode(githubRepos)
            cachedGithubReposData = encoded
        } catch {
            // Ignore cache failures
        }
    }

    func fetchGitHubRepos() async {
        let username = githubUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return }
        let token = githubUseAuth ? githubToken.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        
        do {
            let repos = try await GitHubService.shared.fetchRepos(username: username, token: token.isEmpty ? nil : token)
            githubRepos = repos
            saveCachedGitHubRepos()
        } catch {
            // Keep last cached repos if fetch fails
        }
    }

    func addExcludedSubfolder(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var current = excludedSubfolderList
        if current.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return
        }
        current.append(trimmed)
        objectWillChange.send()
        excludedSubfolders = current.joined(separator: "\n")
    }

    func removeExcludedSubfolder(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let updated = excludedSubfolderList.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        objectWillChange.send()
        excludedSubfolders = updated.joined(separator: "\n")
    }
}
