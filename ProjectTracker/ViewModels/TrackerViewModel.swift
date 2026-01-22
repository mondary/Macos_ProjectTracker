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
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var timer: Timer?
    
    init() {
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
        isScanning = false
    }
}
