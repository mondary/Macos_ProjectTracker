import SwiftUI
import AppKit

struct ProjectListView: View {
    @ObservedObject var viewModel: TrackerViewModel
    @Environment(\.openSettings) private var openSettings
    @State private var displayMode: DisplayMode = .twoColumns
    @State private var sortOption: SortOption = .name
    @State private var sortAscending = false
    @State private var didCopyLog = false
    
    var body: some View {
        VStack(spacing: 16) {
            header
            statsRow
            searchRow
            statusLegend
            projectContent
            footer
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 640)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Project Tracker")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                
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
    
    private var searchRow: some View {
        HStack(spacing: 10) {
            searchBar
            displayModeControl
            sortControl
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
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private var displayModeControl: some View {
        Picker("Affichage", selection: $displayMode) {
            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Image(systemName: mode.icon).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
    }

    private var sortControl: some View {
        HStack(spacing: 6) {
            Menu {
                Picker("Trier par", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
            } label: {
                Label("Trier", systemImage: "line.3.horizontal.decrease.circle")
                    .labelStyle(.iconOnly)
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Trier par")

            Button {
                sortAscending.toggle()
            } label: {
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(sortAscending ? "Ordre croissant" : "Ordre décroissant")
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .frame(width: 68)
    }
    
    private var projectContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let filtered = viewModel.filteredProjects
                let changed = sortProjects(filtered.filter { $0.hasChanges })
                let clean = sortProjects(filtered.filter { !$0.hasChanges })
                
                if !changed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Actions requises", count: changed.count, accent: Color(red: 0.92, green: 0.54, blue: 0.36))
                        if displayMode == .list {
                            VStack(spacing: 8) {
                                ForEach(changed) { project in
                                    ProjectRow(project: project, compact: false)
                                }
                            }
                        } else {
                            LazyVGrid(columns: displayMode.columns, spacing: 8) {
                                ForEach(changed) { project in
                                    ProjectRow(project: project, compact: displayMode.compactRows)
                                }
                            }
                        }
                    }
                }
                
                if !clean.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Tout est à jour", count: clean.count, accent: Color(red: 0.48, green: 0.78, blue: 0.55))
                        
                        if displayMode == .list {
                            VStack(spacing: 8) {
                                ForEach(clean) { project in
                                    ProjectRow(project: project, compact: false)
                                }
                            }
                        } else {
                            LazyVGrid(columns: displayMode.columns, spacing: 8) {
                                ForEach(clean) { project in
                                    ProjectRow(project: project, compact: displayMode.compactRows)
                                }
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
        .frame(maxHeight: .infinity)
        .layoutPriority(1)
    }
    
    private var footer: some View {
        HStack {
            HStack(spacing: 4) {
                Text("Surveillance :")
                    .fontWeight(.semibold)
                Text(viewModel.scanPath)
                    .textSelection(.enabled)
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.8))
            .lineLimit(1)
            .truncationMode(.head)
            
            if let lastScan = viewModel.lastScanDate {
                Text("•")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Text("Scan : \(lastScan, style: .time)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()

            Button("Log") {
                copyScanLog()
            }
            .buttonStyle(.link)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .help("Copier le log de scan")

            if didCopyLog {
                Text("Copié")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Button("Réglages") {
                openSettings()
            }
            .buttonStyle(.link)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            
            Button("Quitter") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .padding(.vertical, 2)
        .frame(height: 22)
    }

    private func copyScanLog() {
        let log = viewModel.lastScanLog.isEmpty ? "No scan log available." : viewModel.lastScanLog
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(log, forType: .string)
        didCopyLog = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            didCopyLog = false
        }
    }
    
    private var statusLegend: some View {
        HStack(spacing: 8) {
            LegendItem(color: .red, icon: "pencil", text: "Modifié")
            LegendItem(color: .blue, icon: "arrow.up", text: "À envoyer")
            LegendItem(color: .purple, icon: "arrow.down", text: "En retard")
            LegendItem(color: .green, icon: "checkmark.seal.fill", text: "À jour")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct ProjectRow: View {
    let project: Project
    let compact: Bool
    
    var body: some View {
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
                LinkIconButton(label: "Ouvrir dans Finder") {
                    openInFinder()
                } content: {
                    Image(systemName: "folder")
                        .font(.system(size: 12, weight: .semibold))
                }
                
                if let githubURL = githubWebURL {
                    LinkIconButton(label: "Ouvrir le dépôt GitHub") {
                        NSWorkspace.shared.open(githubURL)
                    } content: {
                        GitHubLogoView()
                    }
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
        .contentShape(Rectangle())
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var githubWebURL: URL? {
        guard let remote = project.remoteURL, !remote.isEmpty else { return nil }
        let normalized = normalizeGitRemote(remote)
        return URL(string: normalized)
    }
    
    private func openInFinder() {
        if let url = URL(string: "file://\(project.path)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func normalizeGitRemote(_ remote: String) -> String {
        var normalized = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalized.hasPrefix("git@github.com:") {
            normalized = normalized.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
        } else if normalized.hasPrefix("ssh://git@github.com/") {
            normalized = normalized.replacingOccurrences(of: "ssh://git@github.com/", with: "https://github.com/")
        } else if normalized.hasPrefix("git://github.com/") {
            normalized = normalized.replacingOccurrences(of: "git://github.com/", with: "https://github.com/")
        } else if normalized.contains("github.com") && !(normalized.hasPrefix("https://") || normalized.hasPrefix("http://")) {
            normalized = "https://" + normalized.replacingOccurrences(of: "github.com/", with: "github.com/")
        }
        
        if normalized.hasSuffix(".git") {
            normalized = String(normalized.dropLast(4))
        }
        
        return normalized
    }
}

struct LinkIconButton<Content: View>: View {
    let label: String
    let action: () -> Void
    let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            content()
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .accessibilityLabel(label)
        .help(label)
    }
}

struct GitHubLogoView: View {
    var body: some View {
        if let nsImage = svgImage {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .padding(3)
        } else {
            Image(systemName: "link")
                .font(.system(size: 12, weight: .semibold))
        }
    }
    
    private var svgImage: NSImage? {
        guard let url = Bundle.module.url(forResource: "github", withExtension: "svg"),
              let data = try? Data(contentsOf: url),
              let image = NSImage(data: data) else {
            return nil
        }
        image.isTemplate = true
        return image
    }
}

enum DisplayMode: CaseIterable {
    case list
    case twoColumns
    case threeColumns
    case compact
    
    var label: String {
        switch self {
        case .list: return "Liste"
        case .twoColumns: return "2 colonnes"
        case .threeColumns: return "3 colonnes"
        case .compact: return "Compact"
        }
    }

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .twoColumns: return "rectangle.grid.2x2"
        case .threeColumns: return "rectangle.grid.3x2"
        case .compact: return "square.grid.4x3.fill"
        }
    }
    
    var columns: [GridItem] {
        switch self {
        case .twoColumns:
            return [GridItem(.flexible()), GridItem(.flexible())]
        case .threeColumns:
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        case .compact:
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        case .list:
            return []
        }
    }
    
    var compactRows: Bool {
        switch self {
        case .list:
            return false
        case .twoColumns, .threeColumns, .compact:
            return true
        }
    }
}

enum SortOption: CaseIterable {
    case status
    case name
    case folder
    
    var label: String {
        switch self {
        case .status: return "Statut"
        case .name: return "Nom"
        case .folder: return "Dossier"
        }
    }
}

extension ProjectListView {
    private func sortProjects(_ projects: [Project]) -> [Project] {
        let sorted = projects.sorted { lhs, rhs in
            switch sortOption {
            case .name:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .folder:
                let leftFolder = URL(fileURLWithPath: lhs.path).deletingLastPathComponent().path
                let rightFolder = URL(fileURLWithPath: rhs.path).deletingLastPathComponent().path
                if leftFolder == rightFolder {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return leftFolder.localizedCaseInsensitiveCompare(rightFolder) == .orderedAscending
            case .status:
                let leftRank = statusRank(for: lhs)
                let rightRank = statusRank(for: rhs)
                if leftRank == rightRank {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return leftRank < rightRank
            }
        }
        
        return sortAscending ? sorted : sorted.reversed()
    }
    
    private func statusRank(for project: Project) -> Int {
        if project.isDirty { return 0 }
        if project.aheadCount > 0 { return 1 }
        if project.behindCount > 0 { return 2 }
        return 3
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

struct LegendItem: View {
    let color: Color
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            StatusBadge(color: color, icon: icon, text: "")
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
