import SwiftUI

struct ProjectListView: View {
    @ObservedObject var viewModel: TrackerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            Divider()
            
            projectList
            
            Divider()
            
            footer
        }
        .frame(width: 320)
        .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Project Tracker")
                    .font(.system(.headline, design: .rounded))
                if let lastScan = viewModel.lastScanDate {
                    Text("Updated \(lastScan, style: .time)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if viewModel.isScanning {
                ProgressView()
                    .controlSize(.small)
                    .transition(.opacity)
            } else {
                Button(action: {
                    Task {
                        await viewModel.scan()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Refresh now")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var projectList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if viewModel.projects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("No Git projects found in Documents/GitHub")
                            .font(.system(.caption, design: .rounded))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    let changed = viewModel.projects.filter { $0.hasChanges }
                    let clean = viewModel.projects.filter { !$0.hasChanges }
                    
                    if !changed.isEmpty {
                        SectionHeader(title: "Needs Attention")
                        ForEach(changed) { project in
                            ProjectRow(project: project)
                        }
                    }
                    
                    if !clean.isEmpty {
                        SectionHeader(title: "Up to Date")
                        ForEach(clean) { project in
                            ProjectRow(project: project)
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 450)
    }
    
    private var footer: some View {
        HStack {
            Button("Settings...") {
                // Placeholder for settings
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.secondary)
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(.caption, design: .rounded))
            .fontWeight(.medium)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.leading, 4)
            .padding(.top, 8)
    }
}

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.branch")
                        .font(.system(size: 9))
                    Text(project.branch)
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.secondary)
                
                if let summary = project.summary {
                    Text(summary)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if project.isDirty {
                    StatusBadge(color: .orange, icon: "pencil.circle.fill", text: "Modified")
                }
                
                if project.aheadCount > 0 {
                    StatusBadge(color: .blue, icon: "arrow.up.circle.fill", text: "\(project.aheadCount)")
                }
                
                if project.behindCount > 0 {
                    StatusBadge(color: .purple, icon: "arrow.down.circle.fill", text: "\(project.behindCount)")
                }
                
                if !project.hasChanges {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

struct StatusBadge: View {
    let color: Color
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 9, weight: .bold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

// Utility view for translucency
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
