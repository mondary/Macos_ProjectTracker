import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TrackerViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Configuration").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dossier à surveiller")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(alignment: .firstTextBaseline) {
                        TextField("Chemin du dossier", text: $viewModel.scanPath)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.leading)
                        
                        Button("Choisir...") {
                            selectFolder()
                        }
                    }
                    
                    Text("L'application scannera tous les sous-dossiers de ce répertoire pour trouver des dépôts Git.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("IA Summarizer").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration des clés API")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 8) {
                        APIKeyField(label: "OpenAI", text: $viewModel.openAIKey)
                        APIKeyField(label: "Gemini", text: $viewModel.geminiKey)
                        APIKeyField(label: "OpenRouter", text: $viewModel.openRouterKey)
                    }
                    
                    Text("L'application utilisera la première clé disponible pour générer les résumés.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 480)
        .navigationTitle("Réglages - Project Tracker")
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                viewModel.scanPath = url.path
                // Trigger a re-scan automatically when the path changes
                Task {
                    await viewModel.scan()
                }
            }
        }
    }
}

struct APIKeyField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 80, alignment: .leading)
            
            SecureField("sk-...", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
