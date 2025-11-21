//
//  SymptomsView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct SymptomsView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Extracted Symptoms
                VStack(alignment: .leading, spacing: 16) {
                    Text("Extracted Symptoms")
                        .font(.title2)
                        .bold()

                    if viewModel.extractedSymptoms.isEmpty {
                        Text("No symptoms extracted yet. Please analyze your medical data first.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.extractedSymptoms) { symptom in
                                SymptomCard(
                                    symptom: symptom,
                                    isSelected: viewModel.confirmedSymptoms.contains(symptom),
                                    action: {
                                        viewModel.toggleSymptom(symptom)
                                    },
                                    chatAction: {
                                        viewModel.startSymptomChat(with: symptom)
                                    }
                                )
                            }
                        }
                    }
                }

                // Additional Symptoms
                VStack(alignment: .leading, spacing: 16) {
                    Text("Additional Symptoms")
                        .font(.title2)
                        .bold()

                    TextEditor(text: $viewModel.additionalSymptoms)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if viewModel.additionalSymptoms.isEmpty {
                                    Text("Enter any additional symptoms you're experiencing (comma-separated)...")
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
                        if await viewModel.analyzeCauses() {
                            viewModel.selectedTab = 2 // Go to Causes tab
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Analyzing...")
                        } else {
                            Text("Find Potential Causes")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (viewModel.confirmedSymptoms.isEmpty && viewModel.additionalSymptoms.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading) ? Color.gray : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.confirmedSymptoms.isEmpty && viewModel.additionalSymptoms.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            .padding()
        }
    }
}

struct SymptomCard: View {
    let symptom: Symptom
    let isSelected: Bool
    let action: () -> Void
    let chatAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: action) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(symptom.symptom)
                                .font(.headline)
                                .foregroundColor(.primary)

                            SeverityBadge(severity: symptom.severity)
                        }

                        Text("Source: \(symptom.source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .green : .gray)
                }
            }
            .buttonStyle(PlainButtonStyle()) // Important to allow nested buttons if needed, though here we are separating them

            // Chat Button
            Button(action: chatAction) {
                Image(systemName: "message.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

struct SeverityBadge: View {
    let severity: Symptom.Severity

    var body: some View {
        Text(severity.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
    }

    private var backgroundColor: Color {
        switch severity {
        case .severe: return .red.opacity(0.2)
        case .moderate: return .yellow.opacity(0.2)
        case .mild: return .blue.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch severity {
        case .severe: return .red
        case .moderate: return .orange
        case .mild: return .blue
        }
    }
}
