import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let baseDir: URL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    private var configURL: URL { baseDir.appendingPathComponent("config.json") }
    private var animTimer: Timer?
    private var animState = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "bolt.horizontal.circle", accessibilityDescription: "Project Tracker") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "PT"
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Lancer le scan", action: #selector(runScan), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Ouvrir le rapport", action: #selector(openReport), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Changer le dossier…", action: #selector(changeFolder), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func runScan() {
        let cmd = "cd '\(shellEscape(baseDir.path))' && source .venv/bin/activate && python3 tracker.py"
        startAnimation()
        runShell(cmd) { [weak self] in
            DispatchQueue.main.async {
                self?.stopAnimation()
            }
        }
    }

    @objc private func openReport() {
        let report = baseDir.appendingPathComponent("report.html").path
        runShell("open '\(shellEscape(report))'")
    }

    @objc private func changeFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choisir le dossier de projets"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choisir"
        if panel.runModal() == .OK, let url = panel.url {
            updateConfigProjectsDirectory(url.path)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func runShell(_ cmd: String, onExit: (() -> Void)? = nil) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-lc", cmd]
        if let onExit {
            task.terminationHandler = { _ in onExit() }
        }
        task.launch()
    }

    private func shellEscape(_ s: String) -> String {
        return s.replacingOccurrences(of: "'", with: "'\\''")
    }

    private func updateConfigProjectsDirectory(_ path: String) {
        guard let data = try? Data(contentsOf: configURL) else { return }
        guard var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }
        json["projects_directory"] = path
        if let out = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
            try? out.write(to: configURL)
        }
    }

    private func startAnimation() {
        guard animTimer == nil else { return }
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.toggleIcon()
        }
        toggleIcon()
    }

    private func stopAnimation() {
        animTimer?.invalidate()
        animTimer = nil
        animState = false
        setIcon(named: "bolt.horizontal.circle")
    }

    private func toggleIcon() {
        animState.toggle()
        let name = animState ? "arrow.triangle.2.circlepath" : "bolt.horizontal.circle"
        setIcon(named: name)
    }

    private func setIcon(named name: String) {
        guard let button = statusItem.button else { return }
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: "Project Tracker") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "PT"
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
