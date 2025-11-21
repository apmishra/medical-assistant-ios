//
//  SettingsView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var tempApiKey: String = ""
    @State private var showingSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Provider Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Provider")
                        .font(.headline)
                    
                    Picker("Provider", selection: $viewModel.selectedProvider) {
                        ForEach(LLMProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.selectedProvider) { newValue in
                        viewModel.saveProvider(newValue)
                        // Update temp key to match selected provider
                        switch newValue {
                        case .claude: tempApiKey = viewModel.apiKey
                        case .gemini: tempApiKey = viewModel.geminiApiKey
                        case .openai: tempApiKey = viewModel.openaiApiKey
                        case .ollama: break // Bindings used directly
                        }
                    }
                }
                
                Divider()

                // API Key / Configuration Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(viewModel.selectedProvider.rawValue) Configuration")
                        .font(.headline)

                    if viewModel.selectedProvider == .ollama {
                        // Ollama Specific Fields
                        VStack(alignment: .leading) {
                            Text("Base URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("http://localhost:11434", text: $viewModel.ollamaBaseURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Model Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("llama3", text: $viewModel.ollamaModel)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: {
                            viewModel.saveOllamaConfig(url: viewModel.ollamaBaseURL, model: viewModel.ollamaModel)
                            showingSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showingSaved = false
                            }
                        }) {
                            Text("Update Configuration")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else {
                        // Standard API Key Field
                        SecureField("Enter \(viewModel.selectedProvider.rawValue) API key", text: $tempApiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        Button(action: {
                            switch viewModel.selectedProvider {
                            case .claude: viewModel.saveAPIKey(tempApiKey)
                            case .gemini: viewModel.saveGeminiAPIKey(tempApiKey)
                            case .openai: viewModel.saveOpenAIAPIKey(tempApiKey)
                            case .ollama: break // Handled above
                            }
                            showingSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showingSaved = false
                            }
                        }) {
                            Text("Update Key")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }

                    Text(viewModel.selectedProvider == .ollama ? "Configuration is stored locally." : "Your API key is stored locally on your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if showingSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Saved successfully!")
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }
                }
                .onAppear {
                    // Initialize temp key
                    switch viewModel.selectedProvider {
                    case .claude: tempApiKey = viewModel.apiKey
                    case .gemini: tempApiKey = viewModel.geminiApiKey
                    case .openai: tempApiKey = viewModel.openaiApiKey
                    case .ollama: break // Bindings used directly
                    }
                }

                Divider()

                // API Key Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Key Status")
                        .font(.headline)

                    HStack {
                        Image(systemName: viewModel.apiKey.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(viewModel.apiKey.isEmpty ? .red : .green)
                        Text(viewModel.apiKey.isEmpty ? "Claude: Not Configured" : "Claude: Configured")
                            .foregroundColor(viewModel.apiKey.isEmpty ? .red : .green)
                    }
                    
                    HStack {
                        Image(systemName: viewModel.geminiApiKey.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(viewModel.geminiApiKey.isEmpty ? .red : .green)
                        Text(viewModel.geminiApiKey.isEmpty ? "Gemini: Not Configured" : "Gemini: Configured")
                            .foregroundColor(viewModel.geminiApiKey.isEmpty ? .red : .green)
                    }
                    
                    HStack {
                        Image(systemName: viewModel.openaiApiKey.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(viewModel.openaiApiKey.isEmpty ? .red : .green)
                        Text(viewModel.openaiApiKey.isEmpty ? "OpenAI: Not Configured" : "OpenAI: Configured")
                            .foregroundColor(viewModel.openaiApiKey.isEmpty ? .red : .green)
                    }
                    
                    HStack {
                        Image(systemName: (viewModel.ollamaBaseURL.isEmpty || viewModel.ollamaModel.isEmpty) ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor((viewModel.ollamaBaseURL.isEmpty || viewModel.ollamaModel.isEmpty) ? .red : .green)
                        Text((viewModel.ollamaBaseURL.isEmpty || viewModel.ollamaModel.isEmpty) ? "Ollama: Not Configured" : "Ollama: Configured")
                            .foregroundColor((viewModel.ollamaBaseURL.isEmpty || viewModel.ollamaModel.isEmpty) ? .red : .green)
                    }
                }

                Divider()

                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About This Application")
                        .font(.headline)

                    Text("This medical assistant application helps analyze medical documents and provides information about potential symptoms, causes, and treatment options.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model: Claude Sonnet 4 (claude-sonnet-4-20250514)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Platform: iOS Native (SwiftUI)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Direct API: Anthropic API")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                Divider()

                // Disclaimer
                VStack(alignment: .leading, spacing: 12) {
                    Text("Important Disclaimer")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text("This application is for informational purposes only. The information provided is AI-generated and should NOT be considered medical advice. Always consult with qualified healthcare professionals for medical diagnosis and treatment.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}
