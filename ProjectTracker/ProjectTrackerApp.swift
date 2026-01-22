import SwiftUI

@main
struct ProjectTrackerApp: App {
    @StateObject private var viewModel = TrackerViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        WindowGroup("Project Tracker", id: "main") {
            ProjectListView(viewModel: viewModel)
        }

        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                Button("Ouvrir Project Tracker") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                
                Button("Scanner maintenant") {
                    Task { await viewModel.scan() }
                }
                
                Divider()
                
                Button("Réglages") {
                    openSettings()
                }
                
                Button("Quitter") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(8)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.isScanning ? "arrow.triangle.2.circlepath" : "point.3.connected.trianglepath.dotted")
                
                let changeCount = viewModel.projects.filter({ $0.hasChanges }).count
                if changeCount > 0 {
                    Text("\(changeCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
