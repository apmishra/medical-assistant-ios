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
                        case .appleIntelligence: break
                        }
                    }
                }
                
                Divider()
                
                // LLM Tuning Parameters
                VStack(alignment: .leading, spacing: 16) {
                    Text("LLM Tuning Parameters")
                        .font(.headline)
                    
                    // Temperature
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.2f", viewModel.temperature))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $viewModel.temperature, in: 0.0...2.0, step: 0.1)
                        Text("Controls randomness. Lower = more focused, Higher = more creative")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Max Tokens
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Max Tokens")
                                .font(.subheadline)
                            Spacer()
                            Text("\(viewModel.maxTokens)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(viewModel.maxTokens) },
                            set: { viewModel.maxTokens = Int($0) }
                        ), in: 512...8192, step: 256)
                        Text("Maximum tokens for response. Values below 1024 may cause incomplete JSON responses.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    // Top P
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Top P")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.2f", viewModel.topP))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $viewModel.topP, in: 0.0...1.0, step: 0.05)
                        Text("Nucleus sampling. Lower = more deterministic")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Custom System Prompt
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom System Prompt")
                            .font(.subheadline)
                        TextEditor(text: $viewModel.customSystemPrompt)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        Text("Optional custom instructions prepended to all AI requests")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Treatment Recommendation Count
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Treatment Recommendations")
                                .font(.subheadline)
                            Spacer()
                            Text("\(viewModel.treatmentRecommendationCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                        get: { Double(viewModel.treatmentRecommendationCount) },
                        set: { viewModel.treatmentRecommendationCount = Int($0) }
                    ), in: 1...10, step: 1)
                    
                    Text("\(viewModel.treatmentRecommendationCount) recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Question Answer Count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question Answer Count")
                        .font(.headline)
                    
                    Text("Number of answers to generate for each doctor question")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(viewModel.questionAnswerCount) },
                        set: { viewModel.questionAnswerCount = Int($0) }
                    ), in: 1...10, step: 1)
                    
                    Text("\(viewModel.questionAnswerCount) answers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Debug Button
                NavigationLink(destination: DebugView().environmentObject(viewModel)) {
                    HStack {
                        Image(systemName: "ladybug.fill")
                            .foregroundColor(.orange)
                        Text("Debug Logs")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                        viewModel.saveLLMTuningParameters(
                            temperature: viewModel.temperature,
                            maxTokens: viewModel.maxTokens,
                            topP: viewModel.topP,
                            customSystemPrompt: viewModel.customSystemPrompt
                        )
                        showingSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingSaved = false
                        }
                    }) {
                        Text("Save Tuning Parameters")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
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
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Model Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("llama3", text: $viewModel.ollamaModel)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
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
                    } else if viewModel.selectedProvider == .appleIntelligence {
                        VStack(spacing: 12) {
                            Image(systemName: "applelogo")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                            Text("Apple Intelligence")
                                .font(.headline)
                            Text("Uses on-device Foundation Models. No API key required.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        // Standard API Key Field
                        SecureField("Enter \(viewModel.selectedProvider.rawValue) API key", text: $tempApiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button(action: {
                            switch viewModel.selectedProvider {
                            case .claude: viewModel.saveAPIKey(tempApiKey)
                            case .gemini: viewModel.saveGeminiAPIKey(tempApiKey)
                            case .openai: viewModel.saveOpenAIAPIKey(tempApiKey)
                            case .ollama: break // Handled above
                            case .appleIntelligence: break
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
                    case .appleIntelligence: break
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
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Apple Intelligence: Ready")
                            .foregroundColor(.green)
                    }
                }

                Divider()

                // Category Management
                CategoryManagementView()
                    .environmentObject(viewModel)

                Divider()

                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About This Application")
                        .font(.headline)

                    Text("This Barbarik application helps analyze medical documents and provides information about potential symptoms, causes, and treatment options.")
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
