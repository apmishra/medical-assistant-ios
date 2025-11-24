//
//  MedicalHistoryView.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import SwiftUI

struct MedicalHistoryView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @FocusState private var isFocused: Bool
    @State private var showingSaved = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical History")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Information provided here will be used to give better context for AI analysis.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Existing Issues Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Existing Medical Issues", systemImage: "heart.text.square")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        TextEditor(text: $viewModel.existingMedicalIssues)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($isFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        Text("e.g., Diabetes Type 2, Hypertension, Asthma, recent surgeries...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Medications Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Current Medications", systemImage: "pills.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        TextEditor(text: $viewModel.currentMedications)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($isFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        Text("e.g., Metformin 500mg, Lisinopril 10mg, daily vitamins...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Save Button
                    Button(action: {
                        viewModel.saveMedicalHistory()
                        showingSaved = true
                        isFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showingSaved = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Medical History")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Success Message
                    if showingSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Medical history saved successfully!")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onTapGesture {
                isFocused = false
            }
        }
    }
}

struct MedicalHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MedicalHistoryView()
            .environmentObject(MedicalAssistantViewModel())
    }
}
