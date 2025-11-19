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
    @State private var apiKeyInput: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Configure Claude API Key")
                    .font(.title2)
                    .bold()

                Text("Please enter your Claude API key to use this application.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                SecureField("sk-ant-...", text: $apiKeyInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button(action: {
                    viewModel.saveAPIKey(apiKeyInput)
                    dismiss()
                }) {
                    Text("Save API Key")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(apiKeyInput.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(apiKeyInput.isEmpty)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
