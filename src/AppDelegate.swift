import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app is a regular macOS app (shows in Cmd+Tab / window managers).
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        applyAppIcon()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func applyAppIcon() {
        guard let url = Bundle.module.url(forResource: "icon", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return
        }
        NSApp.applicationIconImage = squareIcon(from: image)
    }

    private func squareIcon(from image: NSImage) -> NSImage {
        let size = image.size
        let side = max(size.width, size.height)
        let square = NSImage(size: NSSize(width: side, height: side))
        square.lockFocus()
        let origin = NSPoint(x: (side - size.width) / 2, y: (side - size.height) / 2)
        image.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
        square.unlockFocus()
        return square
    }
}
