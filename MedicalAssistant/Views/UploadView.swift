//
//  UploadView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var showingFilePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Manual Text Entry (Now First)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paste Medical Text")
                        .font(.title2)
                        .bold()

                    TextEditor(text: $viewModel.manualText)
                        .frame(height: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if viewModel.manualText.isEmpty {
                                    Text("Paste your medical report, blood test results, or doctor's notes here...")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                // Analyze Button
                Button(action: {
                    Task {
                        if await viewModel.analyzeSymptoms() {
                            viewModel.selectedTab = 1 // Go to Symptoms tab
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Analyzing...")
                        } else {
                            Text("Analyze Medical Data")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isLoading || viewModel.manualText.isEmpty)

                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("OR")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }

                // Upload Section (Now Second and Compact)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upload Medical Document")
                        .font(.title3) // Smaller font
                        .bold()

                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.up.doc.fill")
                                .font(.system(size: 24)) // Smaller icon
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload PDF Report")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Tap to select file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }

                do {
                    let data = try Data(contentsOf: url)
                    Task {
                        if await viewModel.handlePDFUpload(data: data) {
                            viewModel.selectedTab = 1 // Go to Symptoms tab
                        }
                    }
                } catch {
                    viewModel.addDebugLog("Failed to read PDF: \(error.localizedDescription)", type: .error)
                }
            }
        case .failure(let error):
            viewModel.addDebugLog("File selection failed: \(error.localizedDescription)", type: .error)
        }
    }
}
