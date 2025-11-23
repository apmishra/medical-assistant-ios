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

    var body: some View {
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
                
                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            isFocused = false
        }
    }
}

struct MedicalHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MedicalHistoryView()
            .environmentObject(MedicalAssistantViewModel())
    }
}
