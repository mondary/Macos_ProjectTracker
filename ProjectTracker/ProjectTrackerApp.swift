import SwiftUI

@main
struct ProjectTrackerApp: App {
    @StateObject private var viewModel = TrackerViewModel()

    var body: some Scene {
        WindowGroup("Project Tracker") {
            ProjectListView(viewModel: viewModel)
        }

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
