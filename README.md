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

## Architecture & Scaffolding

Ce projet a été construit sans interface graphique Xcode, en utilisant exclusivement le **Swift Package Manager (SPM)**. Cette approche moderne offre une structure légère, portable et facile à versionner.

### Pourquoi SPM plutôt qu'un `.xcodeproj` ?
- **Légèreté** : Pas de fichiers de projet opaques et lourds. Toute la configuration est dans `Package.swift`.
- **Flexibilité** : Vous pouvez ouvrir le projet dans Xcode (`open Package.swift`) ou le compiler via le terminal (`swift build`).
- **Standardisation** : Utilise l'arborescence standard recommandée pour les projets Swift modernes.

### Structure du Code (MVVM)
L'application suit le pattern de conception **Model-View-ViewModel** pour une séparation claire des responsabilités :

- **Models (`Project.swift`)** : Définit la donnée (nom, branche, état Git).
- **Views (`ProjectListView.swift`)** : L'interface utilisateur en SwiftUI (MenuBar, badges, listes).
- **ViewModels (`TrackerViewModel.swift`)** : Le chef d'orchestre. Gère l'état de l'application, le timer de rafraîchissement et déclenche les scans.
- **Services** : 
    - `GitService.swift` : Un **Actor** Swift 6 qui gère les processus Git de manière isolée et sécurisée pour la concurrence.
    - `AIService.swift` : Service dédié à l'analyse et à la génération de résumés de projets.

## Technology Stack
- **Swift 6** : Utilisation intensive de la concurrence moderne (Actors, `@MainActor`, `Task`).
- **SwiftUI** : Pour une interface réceptive et native avec effets de translucidité.
- **Git integration** : Exécution de processus natifs pour une précision maximale du statut.

## Customization
- **Scan Path**: Currently hardcoded to `~/Documents/GitHub`. You can change this in `ProjectTracker/ViewModels/TrackerViewModel.swift`.
- **AI API**: The `AIService.swift` is a placeholder where you can integrate your preferred LLM API key.
