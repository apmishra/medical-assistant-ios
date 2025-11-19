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
                // API Key Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Claude API Key")
                        .font(.headline)

                    SecureField("Enter your Claude API key", text: $tempApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: {
                        viewModel.saveAPIKey(tempApiKey)
                        tempApiKey = ""
                        showingSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingSaved = false
                        }
                    }) {
                        Text("Update")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Text("Your API key is stored locally on your device and sent directly to Anthropic's API.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if showingSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Key saved successfully!")
                                .foregroundColor(.green)
                        }
                        .font(.caption)
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
                        Text(viewModel.apiKey.isEmpty ? "No API Key Configured" : "API Key Configured")
                            .foregroundColor(viewModel.apiKey.isEmpty ? .red : .green)
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
