import SwiftUI

@main
struct ProjectTrackerApp: App {
    @StateObject private var viewModel = TrackerViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            ProjectListView(viewModel: viewModel)
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
        .menuBarExtraStyle(.window)
    }
}
