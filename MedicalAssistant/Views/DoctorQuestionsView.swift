//
//  DoctorQuestionsView.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import SwiftUI

struct DoctorQuestionsView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    let cause: MedicalCause
    @State private var showingExplanation = false
    @State private var selectedQuestion: String?
    @State private var questionExplanation: String = ""
    @State private var isLoadingExplanation = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Questions for Your Doctor")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("About: \(cause.condition)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("Tap any question to understand why it's important to ask.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Questions List
                    VStack(spacing: 12) {
                        ForEach(cause.recommendedQuestions, id: \.self) { question in
                            QuestionRow(
                                question: question,
                                isSelected: viewModel.selectedQuestions.contains(where: { $0.question == question && $0.cause == cause.condition }),
                                onToggle: {
                                    if viewModel.selectedQuestions.contains(where: { $0.question == question && $0.cause == cause.condition }) {
                                        if let q = viewModel.selectedQuestions.first(where: { $0.question == question && $0.cause == cause.condition }) {
                                            viewModel.removeQuestion(q)
                                        }
                                    } else {
                                        viewModel.addQuestion(question, for: cause.condition)
                                    }
                                },
                                onTap: {
                                    selectedQuestion = question
                                    loadExplanation(for: question)
                                }
                            )
                        }
                    }
                    
                    // Summary
                    if !viewModel.selectedQuestions.filter({ $0.cause == cause.condition }).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let selectedCount = viewModel.selectedQuestions.filter({ $0.cause == cause.condition }).count
                            Text("Selected Questions (\(selectedCount))")
                                .font(.headline)
                            
                            Text("You've marked \(selectedCount) question\(selectedCount == 1 ? "" : "s") to ask your doctor about \(cause.condition).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
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
            .sheet(isPresented: $showingExplanation) {
                QuestionExplanationView(
                    question: selectedQuestion ?? "",
                    explanation: questionExplanation,
                    isLoading: isLoadingExplanation
                )
            }
        }
    }
    
    private func loadExplanation(for question: String) {
        isLoadingExplanation = true
        showingExplanation = true
        questionExplanation = ""
        
        Task {
            do {
                let explanation = try await viewModel.explainDoctorQuestion(
                    question: question,
                    cause: cause
                )
                await MainActor.run {
                    questionExplanation = explanation
                    isLoadingExplanation = false
                }
            } catch {
                await MainActor.run {
                    questionExplanation = "Failed to load explanation: \(error.localizedDescription)"
                    isLoadingExplanation = false
                }
            }
        }
    }
}

struct QuestionRow: View {
    let question: String
    let isSelected: Bool
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(question)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.body)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuestionExplanationView: View {
    let question: String
    let explanation: String
    let isLoading: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why ask this question?")
                        .font(.headline)
                    
                    Text(question)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Text(explanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Question Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
