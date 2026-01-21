# macOS Project Tracker

A native macOS menu bar application built with SwiftUI and Swift 6 that monitors your Git repositories for changes and unpushed commits.

## Features
- 🚀 **Native Menu Bar App**: Stays in your menu bar for quick status checks.
- 🔍 **Auto-Scanning**: Watches your `~/Documents/GitHub` folder (configurable).
- 🔄 **Scheduled Updates**: Refreshes every hour automatically.
- 🛠️ **Git Status**: Detects uncommitted changes, unpushed commits, and branch names.
- 🤖 **AI Ready**: Framework included for AI-powered project summaries.
- ✨ **Premium UI**: Modern SwiftUI design with translucency and rounded typography.

## How to Run

### Option 1: Run from Terminal (Fastest)
```bash
# In this directory
swift run
```

### Option 2: Open in Xcode (Recommended for Dev)
1. Open the folder in Xcode: `open Package.swift`
2. Select the **ProjectTracker** target.
3. Press **Cmd + R** to run.

## Technology Stack
- **Swift 6**: Leveraging modern concurrency (actors, @MainActor).
- **SwiftUI**: For the responsive and modern user interface.
- **Git integration**: Native process execution for accurate status reporting.

## Customization
- **Scan Path**: Currently hardcoded to `~/Documents/GitHub`. You can change this in `ProjectTracker/ViewModels/TrackerViewModel.swift`.
- **AI API**: The `AIService.swift` is a placeholder where you can integrate your preferred LLM API key.
