import SwiftUI
import AppKit

struct ProjectListView: View {
    @ObservedObject var viewModel: TrackerViewModel
    @Environment(\.openSettings) private var openSettings
    @State private var displayMode: DisplayMode = .twoColumns
    @State private var sortOption: SortOption = .name
    @State private var sortAscending = true
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
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        sortOption = option
                    } label: {
                        if option == sortOption {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Text(option.label)
                        }
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
                Image(systemName: sortAscending ? "arrow.down" : "arrow.up")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(sortAscending ? "A → Z" : "Z → A")
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
                let githubOnly = githubOnlyRepos()
                
                if !changed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Actions requises", count: changed.count, accent: Color(red: 0.92, green: 0.54, blue: 0.36))
                        if sortOption == .status {
                            StatusSectionList(
                                groups: groupByGitHubAndStatus(changed),
                                displayMode: displayMode
                            )
                        } else if sortOption == .folder {
                            FolderSectionList(
                                groups: groupByFolder(changed),
                                displayMode: displayMode
                            )
                        } else {
                            if displayMode == .list {
                                VStack(spacing: 8) {
                                    ForEach(changed) { project in
                                        ProjectRow(project: project, compact: false)
                                    }
                                }
                            } else {
                                ColumnGrid(
                                    projects: changed,
                                    columns: displayMode.columnCount,
                                    compact: displayMode.compactRows
                                )
                            }
                        }
                    }
                }
                
                if !clean.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Tout est à jour", count: clean.count, accent: Color(red: 0.48, green: 0.78, blue: 0.55))
                        
                        if sortOption == .status {
                            StatusSectionList(
                                groups: groupByGitHubAndStatus(clean),
                                displayMode: displayMode
                            )
                        } else if sortOption == .folder {
                            FolderSectionList(
                                groups: groupByFolder(clean),
                                displayMode: displayMode
                            )
                        } else {
                            if displayMode == .list {
                                VStack(spacing: 8) {
                                    ForEach(clean) { project in
                                        ProjectRow(project: project, compact: false)
                                    }
                                }
                            } else {
                                ColumnGrid(
                                    projects: clean,
                                    columns: displayMode.columnCount,
                                    compact: displayMode.compactRows
                                )
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
                
                if !githubOnly.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "GitHub uniquement", count: githubOnly.count, accent: Color(red: 0.62, green: 0.74, blue: 0.92))
                        
                        if displayMode == .list {
                            VStack(spacing: 8) {
                                ForEach(githubOnly, id: \.id) { repo in
                                    GitHubRepoRow(repo: repo)
                                }
                            }
                        } else {
                            ColumnGridRepos(repos: githubOnly, columns: displayMode.columnCount)
                        }
                    }
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

    private func githubOnlyRepos() -> [GitHubRepo] {
        let localNames = Set(viewModel.projects.map { $0.name.lowercased() })
        return viewModel.githubRepos.filter { !localNames.contains($0.name.lowercased()) }
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
    @State private var showReadmeSummary = false
    
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
                        
                        if let description = project.description, !description.isEmpty {
                            Text(description)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
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
                    if let githubURL = githubWebURL {
                        LinkIconButton(label: "Ouvrir le dépôt GitHub") {
                            NSWorkspace.shared.open(githubURL)
                        } content: {
                            GitHubLogoView()
                        }
                    }
                    
                    if project.hasIcon {
                        ProjectIconView(path: project.path)
                    } else {
                        StatusBadge(color: .orange, icon: "photo.slash", text: compact ? "" : "Sans icon")
                    }

                    if project.hasReadme {
                        Button {
                            showReadmeSummary.toggle()
                        } label: {
                            StatusBadge(color: .indigo, icon: "doc.text", text: compact ? "" : "README")
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showReadmeSummary, arrowEdge: .bottom) {
                            ReadmeSummaryView(title: project.name, summary: project.summary)
                        }
                    } else {
                        StatusBadge(color: .orange, icon: "doc.text.magnifyingglass", text: compact ? "" : "Sans README")
                    }

                    LinkIconButton(label: "Ouvrir dans Finder") {
                        openInFinder()
                    } content: {
                        Image(systemName: "folder")
                            .font(.system(size: 12, weight: .semibold))
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

struct FolderSectionList: View {
    let groups: [(folder: String, projects: [Project])]
    let displayMode: DisplayMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(groups, id: \.folder) { group in
                FolderSectionHeader(folder: group.folder)
                
                if displayMode == .list {
                    VStack(spacing: 8) {
                        ForEach(group.projects) { project in
                            ProjectRow(project: project, compact: false)
                        }
                    }
                } else {
                    ColumnGrid(
                        projects: group.projects,
                        columns: displayMode.columnCount,
                        compact: displayMode.compactRows
                    )
                }
            }
        }
    }
}

struct FolderSectionHeader: View {
    let folder: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            Text(folder)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.head)
            Spacer()
        }
        .padding(.vertical, 2)
        .overlay(
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)
                .offset(y: 10),
            alignment: .bottom
        )
    }
}

struct StatusSectionList: View {
    let groups: [GitHubStatusGroup]
    let displayMode: DisplayMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(groups) { group in
                StatusGroupHeader(title: group.title)
                
                ForEach(group.statusGroups, id: \.status) { statusGroup in
                    StatusBucketHeader(title: statusGroup.status.label)
                    
                    if displayMode == .list {
                        VStack(spacing: 8) {
                            ForEach(statusGroup.projects) { project in
                                ProjectRow(project: project, compact: false)
                            }
                        }
                    } else {
                        ColumnGrid(
                            projects: statusGroup.projects,
                            columns: displayMode.columnCount,
                            compact: displayMode.compactRows
                        )
                    }
                }
            }
        }
    }
}

struct StatusGroupHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 2)
        .overlay(
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)
                .offset(y: 10),
            alignment: .bottom
        )
    }
}

struct StatusBucketHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.top, 2)
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

    var columnCount: Int {
        switch self {
        case .list: return 1
        case .twoColumns: return 2
        case .threeColumns: return 3
        case .compact: return 4
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

struct ColumnGrid: View {
    let projects: [Project]
    let columns: Int
    let compact: Bool
    
    var body: some View {
        let buckets = distribute(projects, into: max(1, columns))
        return HStack(alignment: .top, spacing: 8) {
            ForEach(0..<buckets.count, id: \.self) { index in
                VStack(spacing: 8) {
                    ForEach(buckets[index]) { project in
                        ProjectRow(project: project, compact: compact)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
    
    private func distribute(_ items: [Project], into columns: Int) -> [[Project]] {
        guard columns > 0 else { return [] }
        let total = items.count
        let chunkSize = Int(ceil(Double(total) / Double(columns)))
        var result: [[Project]] = []
        result.reserveCapacity(columns)
        
        for col in 0..<columns {
            let start = col * chunkSize
            let end = min(start + chunkSize, total)
            if start < end {
                result.append(Array(items[start..<end]))
            } else {
                result.append([])
            }
        }
        return result
    }
}

enum SortOption: CaseIterable {
    case name
    case folder
    case status
    
    var label: String {
        switch self {
        case .name: return "Nom"
        case .folder: return "Dossier"
        case .status: return "Statut"
        }
    }
}

enum StatusBucket: CaseIterable {
    case modified
    case ahead
    case behind
    case upToDate
    
    var label: String {
        switch self {
        case .modified: return "Modifié"
        case .ahead: return "À envoyer"
        case .behind: return "En retard"
        case .upToDate: return "À jour"
        }
    }
}

struct StatusGroup {
    let status: StatusBucket
    let projects: [Project]
}

struct GitHubStatusGroup: Identifiable {
    let id = UUID()
    let title: String
    let statusGroups: [StatusGroup]
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

    private func groupByFolder(_ projects: [Project]) -> [(folder: String, projects: [Project])] {
        let grouped = Dictionary(grouping: projects) { project in
            URL(fileURLWithPath: project.path).deletingLastPathComponent().path
        }
        
        let sortedFolders = grouped.keys.sorted { lhs, rhs in
            if sortAscending {
                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedDescending
        }
        
        return sortedFolders.map { folder in
            let projectsInFolder = grouped[folder] ?? []
            let sortedProjects = projectsInFolder.sorted { lhs, rhs in
                if sortAscending {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
            }
            return (folder: folder, projects: sortedProjects)
        }
    }

    private func groupByGitHubAndStatus(_ projects: [Project]) -> [GitHubStatusGroup] {
        let withGitHub = projects.filter { $0.isLinkedToGitHub }
        let withoutGitHub = projects.filter { !$0.isLinkedToGitHub }
        
        return [
            makeGitHubGroup(title: "Avec GitHub", projects: withGitHub),
            makeGitHubGroup(title: "Sans GitHub", projects: withoutGitHub)
        ].filter { !$0.statusGroups.isEmpty }
    }

    private func makeGitHubGroup(title: String, projects: [Project]) -> GitHubStatusGroup {
        var groups: [StatusGroup] = []
        for bucket in StatusBucket.allCases {
            let bucketProjects = projects.filter { bucket.matches($0) }
            if !bucketProjects.isEmpty {
                groups.append(StatusGroup(status: bucket, projects: sortProjects(bucketProjects)))
            }
        }
        return GitHubStatusGroup(title: title, statusGroups: groups)
    }
}

private extension StatusBucket {
    func matches(_ project: Project) -> Bool {
        switch self {
        case .modified:
            return project.isDirty
        case .ahead:
            return project.aheadCount > 0
        case .behind:
            return project.behindCount > 0
        case .upToDate:
            return !project.hasChanges
        }
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

struct GitHubRepoRow: View {
    let repo: GitHubRepo
    
    var body: some View {
        HStack(spacing: 12) {
            GitHubLogoView()
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(repo.name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(repo.htmlURL)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            LinkIconButton(label: "Ouvrir le dépôt GitHub") {
                if let url = URL(string: repo.htmlURL) {
                    NSWorkspace.shared.open(url)
                }
            } content: {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
}

struct ProjectIconView: View {
    let path: String
    
    var body: some View {
        if let image = loadImage() {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
        } else {
            StatusBadge(color: .orange, icon: "photo.slash", text: "")
        }
    }
    
    private func loadImage() -> NSImage? {
        let url = URL(fileURLWithPath: path).appendingPathComponent("icon.png")
        return NSImage(contentsOf: url)
    }
}

struct ReadmeSummaryView: View {
    let title: String
    let summary: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            
            Text(summary?.isEmpty == false ? summary! : "Aucun résumé disponible.")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 280)
    }
}

struct ColumnGridRepos: View {
    let repos: [GitHubRepo]
    let columns: Int
    
    var body: some View {
        let buckets = distribute(repos, into: max(1, columns))
        return HStack(alignment: .top, spacing: 8) {
            ForEach(0..<buckets.count, id: \.self) { index in
                VStack(spacing: 8) {
                    ForEach(buckets[index], id: \.id) { repo in
                        GitHubRepoRow(repo: repo)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
    
    private func distribute(_ items: [GitHubRepo], into columns: Int) -> [[GitHubRepo]] {
        guard columns > 0 else { return [] }
        let total = items.count
        let chunkSize = Int(ceil(Double(total) / Double(columns)))
        var result: [[GitHubRepo]] = []
        result.reserveCapacity(columns)
        
        for col in 0..<columns {
            let start = col * chunkSize
            let end = min(start + chunkSize, total)
            if start < end {
                result.append(Array(items[start..<end]))
            } else {
                result.append([])
            }
        }
        return result
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
