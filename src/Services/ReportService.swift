import Foundation
import AppKit

actor ReportService {
    static let shared = ReportService()
    
    private init() {}
    
    func generateReport(projects: [Project], outputPath: String, scanDate: Date) async {
        let url = URL(fileURLWithPath: outputPath)
        let directory = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let html = buildHTML(projects: projects, scanDate: scanDate)
            try html.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            // Ignore report failures
        }
    }
    
    func openReport(at path: String) async {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
    
    private func buildHTML(projects: [Project], scanDate: Date) -> String {
        let total = projects.count
        let modified = projects.filter { $0.isDirty }.count
        let ahead = projects.filter { $0.aheadCount > 0 }.count
        let behind = projects.filter { $0.behindCount > 0 }.count
        let clean = projects.filter { !$0.hasChanges }.count
        let withGitHub = projects.filter { $0.isLinkedToGitHub }.count
        let withReadme = projects.filter { $0.hasReadme }.count
        let withIcon = projects.filter { $0.hasIcon }.count
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let scanLabel = formatter.string(from: scanDate)
        
        let rows = projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }.map { p in
            """
            <tr>
              <td>\(escape(p.name))</td>
              <td class="mono">\(escape(p.path))</td>
              <td class="mono">\(escape(p.branch))</td>
              <td>\(p.isDirty ? "Oui" : "Non")</td>
              <td>\(p.aheadCount)</td>
              <td>\(p.behindCount)</td>
              <td>\(p.isLinkedToGitHub ? "Oui" : "Non")</td>
              <td>\(p.hasReadme ? "Oui" : "Non")</td>
              <td>\(p.hasIcon ? "Oui" : "Non")</td>
              <td>\(escape(p.description ?? ""))</td>
            </tr>
            """
        }.joined(separator: "\n")
        
        return """
        <!doctype html>
        <html lang="fr">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Project Tracker Report</title>
          <style>
            :root {
              --bg: #0f1115;
              --fg: #e8e8e8;
              --muted: #a6adbb;
              --table: #171a21;
              --border: #2a2f3a;
              --accent: #7bdff2;
            }
            body {
              margin: 24px;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif;
              background: var(--bg);
              color: var(--fg);
            }
            h1 { font-size: 20px; margin: 0 0 6px; }
            .meta { color: var(--muted); margin-bottom: 18px; }
            .cards { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; margin-bottom: 18px; }
            .card { background: var(--table); border: 1px solid var(--border); border-radius: 8px; padding: 10px 12px; }
            .card .label { color: var(--muted); font-size: 11px; }
            .card .value { font-size: 16px; font-weight: 700; }
            table { width: 100%; border-collapse: collapse; background: var(--table); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
            th, td { padding: 10px 12px; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; font-size: 12px; }
            th { background: #11141a; color: var(--accent); position: sticky; top: 0; }
            tr:hover td { background: #141823; }
            .mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace; font-size: 11px; }
          </style>
        </head>
        <body>
          <h1>Project Tracker Report</h1>
          <div class="meta">Généré le \(escape(scanLabel)) • \(total) projet(s)</div>
          <div class="cards">
            <div class="card"><div class="label">Total</div><div class="value">\(total)</div></div>
            <div class="card"><div class="label">À jour</div><div class="value">\(clean)</div></div>
            <div class="card"><div class="label">Modifiés</div><div class="value">\(modified)</div></div>
            <div class="card"><div class="label">GitHub liés</div><div class="value">\(withGitHub)</div></div>
            <div class="card"><div class="label">À envoyer</div><div class="value">\(ahead)</div></div>
            <div class="card"><div class="label">En retard</div><div class="value">\(behind)</div></div>
            <div class="card"><div class="label">README</div><div class="value">\(withReadme)</div></div>
            <div class="card"><div class="label">Icon</div><div class="value">\(withIcon)</div></div>
          </div>
          <table>
            <thead>
              <tr>
                <th>Projet</th>
                <th>Chemin</th>
                <th>Branche</th>
                <th>Modifié</th>
                <th>Ahead</th>
                <th>Behind</th>
                <th>GitHub</th>
                <th>README</th>
                <th>Icon</th>
                <th>Description</th>
              </tr>
            </thead>
            <tbody>
              \(rows)
            </tbody>
          </table>
        </body>
        </html>
        """
    }
    
    private func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#039;")
    }
}
