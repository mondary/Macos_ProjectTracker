# ProjectTracker Release

## About
ProjectTracker is a native macOS menu bar application that monitors your Git repositories for changes and unpushed commits.

## Features
- 🚀 Native Menu Bar App: Stays in your menu bar for quick status checks
- 🔍 Auto-Scanning: Watches your `~/Documents/GitHub` folder (configurable)
- 🔄 Scheduled Updates: Refreshes every hour automatically
- 🛠️ Git Status: Detects uncommitted changes, unpushed commits, and branch names
- 🤖 AI Ready: Framework included for AI-powered project summaries
- ✨ Premium UI: Modern SwiftUI design with translucency and rounded typography

## Installation
1. Download the `ProjectTracker.app` file
2. Drag it to your Applications folder
3. Right-click and choose "Open" (you may need to bypass Gatekeeper)
4. The app will appear in your menu bar

## Usage
- Click the menu bar icon to see project status
- Configure the scan path in Settings
- Add AI API keys for enhanced summaries (optional)
- Projects with changes will show badges indicating:
  - Modified files (pencil icon)
  - Commits to push (up arrow)
  - Commits to pull (down arrow)

## System Requirements
- macOS 14.0 or later
- Git installed and configured

## Configuration
- Default scan path: `~/Documents/GitHub`
- Change this in the Settings panel
- Supports OpenAI, Gemini, or OpenRouter API keys for AI summaries

## Troubleshooting
If the app doesn't launch:
1. Check that you're running macOS 14+
2. Ensure Git is installed (`git --version`)
3. Try launching from Terminal: `/Applications/ProjectTracker.app/Contents/MacOS/ProjectTracker`

## Version
1.0.0

## License
MIT