import Foundation
import SwiftUI

@MainActor
class TrackerViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isScanning = false
    @Published var lastScanDate: Date?
    
    // Default path to scan - could be made configurable
    private let defaultScanPath = NSString(string: "~/Documents/GitHub").expandingTildeInPath
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
        
        // Run directory scanning on a background thread to avoid blocking main
        let path = defaultScanPath
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
