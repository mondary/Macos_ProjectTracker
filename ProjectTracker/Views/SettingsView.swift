import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TrackerViewModel
    
    var body: some View {
        Form {
            Section(header: Label("Configuration", systemImage: "slider.horizontal.3").font(.headline)) {
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
                    
                    HStack(alignment: .center) {
                        Text("Intervalle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 90, alignment: .leading)
                        
                        Stepper(value: $viewModel.scanIntervalMinutes, in: 5...240, step: 5) {
                            Text("\(viewModel.scanIntervalMinutes) min")
                                .frame(minWidth: 70, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Label("IA Summarizer", systemImage: "sparkles").font(.headline)) {
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
                    
                    HStack(spacing: 8) {
                        Link("Clé OpenAI", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        Link("Clé Gemini", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                        Link("Clé OpenRouter", destination: URL(string: "https://openrouter.ai/keys")!)
                    }
                    .font(.caption)
                }
                .padding(.vertical, 8)
            }

            Section(header: Label("GitHub", systemImage: "link").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Utilisateur")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 90, alignment: .leading)
                        
                        TextField("mondary", text: $viewModel.githubUsername)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Toggle("Utiliser un token", isOn: $viewModel.githubUseAuth)
                        .toggleStyle(.switch)
                    
                    HStack(alignment: .center) {
                        Text("Token")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 90, alignment: .leading)
                        
                        SecureField("ghp_...", text: $viewModel.githubToken)
                            .textFieldStyle(.roundedBorder)
                        
                        if !viewModel.githubToken.isEmpty {
                            Button {
                                viewModel.githubToken = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .disabled(!viewModel.githubUseAuth)
                    
                    HStack(spacing: 8) {
                        Button("Rafraîchir") {
                            Task {
                                await viewModel.fetchGitHubRepos()
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Text("Mode public par défaut, token optionnel.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Créer un token GitHub", destination: URL(string: "https://github.com/settings/tokens")!)
                        .font(.caption)
                }
                .padding(.vertical, 8)
            }

            Section(header: Label("Rapport HTML", systemImage: "doc.plaintext").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Chemin")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 90, alignment: .leading)
                        
                        TextField("Chemin du rapport", text: $viewModel.reportPath)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Toggle("Générer automatiquement", isOn: $viewModel.reportAutoGenerate)
                        .toggleStyle(.switch)
                    
                    Toggle("Ouvrir après scan", isOn: $viewModel.reportAutoOpen)
                        .toggleStyle(.switch)
                        .disabled(!viewModel.reportAutoGenerate)
                    
                    HStack(spacing: 8) {
                        Button("Générer maintenant") {
                            Task {
                                await ReportService.shared.generateReport(
                                    projects: viewModel.projects,
                                    outputPath: viewModel.reportPath,
                                    scanDate: viewModel.lastScanDate ?? Date()
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Ouvrir") {
                            Task {
                                await ReportService.shared.openReport(at: viewModel.reportPath)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
        .frame(width: 600, height: 760)
        .navigationTitle("Réglages - Project Tracker")
        .onChange(of: viewModel.scanIntervalMinutes) { _ in
            viewModel.startTimer()
        }
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

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Supprimer la clé \(label)")
                }
                .buttonStyle(.plain)
            }
        }
    }
}
