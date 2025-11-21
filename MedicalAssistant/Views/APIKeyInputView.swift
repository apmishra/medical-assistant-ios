//
//  APIKeyInputView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct APIKeyInputView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedProvider: LLMProvider = .claude
    @State private var apiKeyInput: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Configure API Key")
                    .font(.title2)
                    .bold()

                Text("Select a provider and enter your API key.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedProvider) { newValue in
                    // Pre-fill if we have a key saved for this provider
                    switch newValue {
                    case .claude: apiKeyInput = viewModel.apiKey
                    case .gemini: apiKeyInput = viewModel.geminiApiKey
                    case .openai: apiKeyInput = viewModel.openaiApiKey
                    case .ollama: break
                    }
                }

                VStack(alignment: .leading) {
                    if selectedProvider == .ollama {
                        Text("Base URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("http://localhost:11434", text: $viewModel.ollamaBaseURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Text("Model Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        TextField("llama3", text: $viewModel.ollamaModel)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        Text("\(selectedProvider.rawValue) API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Enter key...", text: $apiKeyInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    viewModel.saveProvider(selectedProvider)
                    switch selectedProvider {
                    case .claude: viewModel.saveAPIKey(apiKeyInput)
                    case .gemini: viewModel.saveGeminiAPIKey(apiKeyInput)
                    case .openai: viewModel.saveOpenAIAPIKey(apiKeyInput)
                    case .ollama: viewModel.saveOllamaConfig(url: viewModel.ollamaBaseURL, model: viewModel.ollamaModel)
                    }
                    dismiss()
                }) {
                    Text("Save & Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((selectedProvider != .ollama && apiKeyInput.isEmpty) ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedProvider != .ollama && apiKeyInput.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Initialize with current ViewModel state
                selectedProvider = viewModel.selectedProvider
                switch selectedProvider {
                case .claude: apiKeyInput = viewModel.apiKey
                case .gemini: apiKeyInput = viewModel.geminiApiKey
                case .openai: apiKeyInput = viewModel.openaiApiKey
                case .ollama: break // Bindings used directly
                }
            }
        }
    }
}
