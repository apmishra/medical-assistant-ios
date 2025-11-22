//
//  TreatmentsView.swift
//  MedicalAssistant
//
//  Created by OpenCode Assistant
//

import SwiftUI

struct TreatmentsView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Treatments")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Treatments you've selected from the causes analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.selectedTreatments.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "pills")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No treatments selected yet")
                                .foregroundColor(.secondary)
                            Text("Go to the Causes tab to select treatments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.selectedTreatments, id: \.id) { treatment in
                                TreatmentCard(
                                    treatment: treatment,
                                    isForSelectedTab: true
                                )
                                .environmentObject(viewModel)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Treatments")
        }
    }
}

struct TreatmentCard: View {
    let treatment: Treatment
    var isForSelectedTab: Bool = false
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(treatment.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(treatment.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isForSelectedTab {
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.startChat(with: treatment)
                        }) {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            viewModel.removeTreatment(treatment)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            if isExpanded {
                Text(treatment.description)
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Source
                HStack(spacing: 8) {
                    Text("Source:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Link(destination: URL(string: treatment.url) ?? URL(string: "https://google.com")!) {
                        HStack(spacing: 4) {
                            Text(treatment.source)
                                .font(.caption)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
                
                // Recommended Questions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Questions:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(treatment.recommendedQuestions, id: \.self) { question in
                        Text("• \(question)")
                            .font(.caption)
                    }
                }
            }
            
            HStack {
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if !isForSelectedTab {
                    Button(action: {
                        viewModel.startChat(with: treatment)
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Chat")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TreatmentsView_Previews: PreviewProvider {
    static var previews: some View {
        TreatmentsView()
            .environmentObject(MedicalAssistantViewModel())
    }
}