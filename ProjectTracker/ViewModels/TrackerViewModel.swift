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
        startTimer()
        Task {
            await scan()
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        // Refresh every hour as requested
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                await self.scan()
            }
        }
    }
    
    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        
        let path = scanPath
        let scannedProjects = await Task.detached {
            await GitService.shared.scanDirectory(at: path)
        }.value
        
        self.projects = scannedProjects.sorted { p1, p2 in
            if p1.hasChanges != p2.hasChanges {
                return p1.hasChanges
            }
            return p1.name < p2.name
        }
        
        lastScanDate = Date()
        saveCachedLastScan()
        saveCachedProjects()
        isScanning = false
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
}
