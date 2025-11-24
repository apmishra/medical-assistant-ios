//
//  CauseTreatmentsView.swift
//  MedicalAssistant
//
//  Created by OpenCode Assistant
//

import SwiftUI

struct CauseTreatmentsView: View {
    let cause: MedicalCause
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var treatmentsByCategory: [String: [Treatment]] = [:]
    @State private var isLoading = false
    @State private var selectedCategory: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var categories: [String] {
        return viewModel.categories.isEmpty ? ["General"] : viewModel.categories
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cause header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(cause.condition)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.startCauseChat(with: cause)
                        }) {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(cause.explanation)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ProbabilityBadge(probability: cause.probability)
                        UrgencyBadge(urgency: cause.urgency)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Category Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                loadTreatments(for: category)
                            }) {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Loading indicator
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Fetching treatments...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                // Treatments for selected category
                else if !selectedCategory.isEmpty && !treatmentsByCategory[selectedCategory, default: []].isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(selectedCategory) Treatments")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(treatmentsByCategory[selectedCategory] ?? [], id: \.id) { treatment in
                            TreatmentWithCheckbox(treatment: treatment, cause: cause.condition)
                        }
                    }
                }
                // No treatments message
                else if !selectedCategory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "pills")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("No \(selectedCategory) treatments available")
                            .foregroundColor(.secondary)
                        
                        Button("Refresh Treatments") {
                            loadTreatments(for: selectedCategory)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if !categories.isEmpty {
                selectedCategory = categories[0]
                loadTreatments(for: selectedCategory)
            }
        }
    }
    
    private func loadTreatments(for category: String) {
        // First check if we already have treatments for this cause and category
        let key = cause.condition
        if let existingTreatments = viewModel.treatmentsByCause[key],
           existingTreatments.contains(where: { $0.source == category }) {
            treatmentsByCategory[category] = existingTreatments.filter({ $0.source == category })
            return
        }
        
        // If not, fetch from API
        Task {
            await fetchTreatments(for: category)
        }
    }
    
    private func fetchTreatments(for category: String) async {
        isLoading = true

        // Check if we already have treatments for this cause and category
        if let existingTreatments = viewModel.treatmentsByCause[cause.condition],
           !existingTreatments.isEmpty {
            let categoryTreatments = existingTreatments.filter { $0.source == category }
            if !categoryTreatments.isEmpty {
                treatmentsByCategory[category] = categoryTreatments
                isLoading = false
                return
            }
        }

        // Fetch new treatments
        let fetchedTreatments = await viewModel.fetchTreatments(for: cause.condition, category: category)

        if !fetchedTreatments.isEmpty {
            treatmentsByCategory[category] = fetchedTreatments

            // Update the ViewModel's treatmentsByCause dictionary
            var allTreatments = viewModel.treatmentsByCause[cause.condition] ?? []
            allTreatments.append(contentsOf: fetchedTreatments)
            viewModel.treatmentsByCause[cause.condition] = allTreatments
        } else {
            errorMessage = "No treatments found for \(category) system for \(cause.condition)"
            showingError = true
        }

        isLoading = false
    }
}

struct TreatmentWithCheckbox: View {
    let treatment: Treatment
    let cause: String
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var isChecked: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                isChecked.toggle()
                viewModel.toggleTreatmentSelection(for: cause, treatment: treatment)
            }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isChecked ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(treatment.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(treatment.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Button(action: {
                    viewModel.startChat(with: treatment)
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Chat about this treatment")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            isChecked = viewModel.isTreatmentSelected(for: cause, treatment: treatment)
        }
    }
}

struct CauseTreatmentsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCause = MedicalCause(
            condition: "Common Cold",
            probability: .high,
            explanation: "Symptoms match typical cold presentation",
            urgency: .routine,
            recommendedQuestions: [
                "How long should I expect symptoms to last?",
                "When should I be concerned about complications?",
                "Are there any warning signs I should watch for?",
                "What over-the-counter medications are safe?",
                "Should I avoid any activities while recovering?"
            ]
        )
        CauseTreatmentsView(cause: sampleCause)
        .environmentObject(MedicalAssistantViewModel())
    }
}