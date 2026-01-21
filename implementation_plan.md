# Implementation Plan - macOS Project Tracker

Developing a native macOS menu bar application using SwiftUI that monitors local Git repositories for changes and unpushed commits.

## Features
- **Menu Bar Integration**: Persistent icon in the macOS menu bar for quick access.
- **Project Scanning**: Automatically scans a designated directory (e.g., `~/Documents/GitHub`) for Git projects.
- **Change Detection**:
    - Detects uncommitted changes (dirty state).
    - Detects unpushed commits (ahead of remote).
    - Detects untracked files.
- **Scheduled Updates**: Runs a background scan every hour (configurable).
- **AI-Powered Summaries (Optional)**: Integration with AI to summarize project status or changes.

## Technical Stack
- **Languages**: Swift 6
- **Frameworks**: SwiftUI, AppKit (for menu bar functionality)
- **Tools**: Git CLI integration via `Process`

## Project Structure
- `ProjectTrackerApp.swift`: Main entry point and MenuBarExtra definition.
- `Models/Project.swift`: Data structure for project status.
- `Services/GitService.swift`: Handles Git commands and directory scanning.
- `Views/ProjectListView.swift`: The UI shown when clicking the menu bar icon.
- `ViewModels/TrackerViewModel.swift`: State management and timer logic.

## Roadmap
1. [ ] Initialize project structure.
2. [ ] Implement Git scanning logic.
3. [ ] Build the Menu Bar interface.
4. [ ] Implement the periodic refresh timer.
5. [ ] Add AI summarization capabilities.
