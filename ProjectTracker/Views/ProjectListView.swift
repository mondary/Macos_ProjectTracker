import SwiftUI

struct ProjectListView: View {
    @ObservedObject var viewModel: TrackerViewModel
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            Divider()
            
            searchBar
            
            Divider()
            
            projectContent
            
            Divider()
            
            footer
        }
        .frame(width: 500) // Much wider for clarity
        .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tableau de bord")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    Label("\(viewModel.projects.count) Projets", systemImage: "folder.fill")
                    Label("\(viewModel.projects.filter({$0.hasChanges}).count) Notifications", systemImage: "bell.badge.fill")
                        .foregroundColor(viewModel.projects.filter({$0.hasChanges}).count > 0 ? .red : .secondary)
                }
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("Surveillance :")
                        .fontWeight(.semibold)
                    Text(viewModel.scanPath)
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.head)
            }
            
            Spacer()
            
            if viewModel.isScanning {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: {
                    Task { await viewModel.scan() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Rechercher un projet...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .rounded))
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var projectContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let filtered = viewModel.filteredProjects
                let changed = filtered.filter { $0.hasChanges }
                let clean = filtered.filter { !$0.hasChanges }
                
                if !changed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Actions requises", count: changed.count)
                        ForEach(changed) { project in
                            ProjectRow(project: project, compact: false)
                        }
                    }
                }
                
                if !clean.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Tout est à jour", count: clean.count)
                        
                        // Using a grid for clean projects to save vertical space
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(clean) { project in
                                ProjectRow(project: project, compact: true)
                            }
                        }
                    }
                }
                
                if filtered.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("Aucun projet trouvé pour \"\(viewModel.searchText)\"")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(20)
        }
        .frame(maxHeight: 550) // Increased height
    }
    
    private var footer: some View {
        HStack {
            if let lastScan = viewModel.lastScanDate {
                Text("Dernier scan : \(lastScan, style: .time)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Réglages") {
                openSettings()
            }
                .buttonStyle(.link)
                .font(.system(.caption, design: .rounded))
            
            Button("Quitter") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .font(.system(.caption, design: .rounded))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int
    var body: some View {
        HStack {
            Text(title.uppercased())
            Spacer()
            Text("\(count)")
                .padding(.horizontal, 6)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(.secondary)
        .padding(.bottom, 4)
    }
}

struct ProjectRow: View {
    let project: Project
    let compact: Bool
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "file://\(project.path)") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                    Text(project.name)
                        .font(.system(compact ? .callout : .subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if !compact {
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
                                .foregroundColor(.secondary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 6) {
                    if project.isDirty {
                        StatusBadge(color: .red, icon: "pencil", text: compact ? "" : "Modifié")
                    }
                    if project.aheadCount > 0 {
                        StatusBadge(color: .blue, icon: "arrow.up", text: compact ? "\(project.aheadCount)" : "\(project.aheadCount) à envoyer")
                    }
                    if project.behindCount > 0 {
                        StatusBadge(color: .purple, icon: "arrow.down", text: compact ? "\(project.behindCount)" : "\(project.behindCount) en retard")
                    }
                    if !project.hasChanges && !compact {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green.opacity(0.7))
                            .font(.system(size: 12))
                    }
                }
            }
            .padding(compact ? 8 : 12)
            .contentShape(Rectangle()) // Make the whole area clickable
        }
        .buttonStyle(.plain) // Remove default button styling
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
    
    // Improved contrast logic: Use a more vibrant color for text on light backgrounds
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            if !text.isEmpty {
                Text(text)
                    .font(.system(size: 9, weight: .heavy))
            }
        }
        .padding(.horizontal, text.isEmpty ? 4 : 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.18))
        .foregroundColor(adjustedColor) // Use a deeper version of the color for text
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(adjustedColor.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private var adjustedColor: Color {
        // On macOS, standard orange is quite light. Let's make it more "Reddish-Orange" for better visibility.
        if color == .orange {
            return Color(nsColor: .systemOrange).opacity(1.0) // System orange is usually beefier
        }
        return color
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
