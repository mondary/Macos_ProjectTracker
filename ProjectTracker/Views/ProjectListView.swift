import SwiftUI

struct ProjectListView: View {
    @ObservedObject var viewModel: TrackerViewModel
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 16) {
                header
                statsRow
                searchBar
                projectContent
                footer
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(18)
        }
        .frame(width: 720, height: 740)
    }
    
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.15, blue: 0.22),
                    Color(red: 0.16, green: 0.18, blue: 0.27),
                    Color(red: 0.20, green: 0.22, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Circle()
                .fill(Color(red: 0.26, green: 0.44, blue: 0.72).opacity(0.35))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: -180, y: -220)
            
            Circle()
                .fill(Color(red: 0.80, green: 0.46, blue: 0.28).opacity(0.25))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: 220, y: 200)
        }
        .ignoresSafeArea()
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Project Tracker")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                
                Text("Vue d'ensemble des dépôts surveillés")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("Surveillance :")
                        .fontWeight(.semibold)
                    Text(viewModel.scanPath)
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.head)
            }
            
            Spacer()
            
            if viewModel.isScanning {
                ProgressView()
                    .controlSize(.regular)
            } else {
                Button(action: {
                    Task { await viewModel.scan() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Scanner")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 4)
    }
    
    private var statsRow: some View {
        let total = viewModel.projects.count
        let needsAttention = viewModel.projects.filter { $0.hasChanges }.count
        let upToDate = viewModel.projects.filter { $0.isUpToDate }.count
        let linked = viewModel.projects.filter { $0.isLinkedToGitHub }.count
        
        return HStack(spacing: 12) {
            StatCard(title: "Total", value: "\(total)", icon: "tray.full", tint: Color(red: 0.46, green: 0.64, blue: 0.90))
            StatCard(title: "À jour", value: "\(upToDate)", icon: "checkmark.seal.fill", tint: Color(red: 0.48, green: 0.78, blue: 0.55))
            StatCard(title: "Attention", value: "\(needsAttention)", icon: "exclamationmark.triangle.fill", tint: Color(red: 0.90, green: 0.56, blue: 0.36))
            StatCard(title: "GitHub", value: "\(linked)", icon: "link.circle.fill", tint: Color(red: 0.62, green: 0.74, blue: 0.92))
        }
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
        .padding(12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
    
    private var projectContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let filtered = viewModel.filteredProjects
                let changed = filtered.filter { $0.hasChanges }
                let clean = filtered.filter { !$0.hasChanges }
                
                if !changed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Actions requises", count: changed.count, accent: Color(red: 0.92, green: 0.54, blue: 0.36))
                        ForEach(changed) { project in
                            ProjectRow(project: project, compact: false)
                        }
                    }
                }
                
                if !clean.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Tout est à jour", count: clean.count, accent: Color(red: 0.48, green: 0.78, blue: 0.55))
                        
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
        .frame(maxHeight: 520)
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
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int
    let accent: Color
    var body: some View {
        HStack {
            Text(title.uppercased())
            Spacer()
            Text("\(count)")
                .padding(.horizontal, 6)
                .background(accent.opacity(0.2))
                .cornerRadius(4)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(accent.opacity(0.9))
        .padding(.bottom, 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(tint)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
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
                        Text(project.path)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                            .truncationMode(.head)
                        
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
                    if project.isLinkedToGitHub {
                        StatusBadge(color: .teal, icon: "link", text: compact ? "" : "GitHub")
                    } else if !compact {
                        StatusBadge(color: .orange, icon: "link.slash", text: "Non lié")
                    }
                    
                    if project.isDirty {
                        StatusBadge(color: .red, icon: "pencil", text: compact ? "" : "Modifié")
                    }
                    if project.aheadCount > 0 {
                        StatusBadge(color: .blue, icon: "arrow.up", text: compact ? "\(project.aheadCount)" : "\(project.aheadCount) à envoyer")
                    }
                    if project.behindCount > 0 {
                        StatusBadge(color: .purple, icon: "arrow.down", text: compact ? "\(project.behindCount)" : "\(project.behindCount) en retard")
                    }
                    if project.isUpToDate && !compact {
                        StatusBadge(color: .green, icon: "checkmark.seal.fill", text: "À jour")
                    }
                }
            }
            .padding(compact ? 8 : 12)
            .contentShape(Rectangle()) // Make the whole area clickable
        }
        .buttonStyle(.plain) // Remove default button styling
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
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
