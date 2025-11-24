//
//  QuestionsView.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import SwiftUI

struct QuestionsView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    
    var questionsByCause: [String: [DoctorQuestion]] {
        Dictionary(grouping: viewModel.selectedQuestions, by: { $0.cause })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Questions for Doctor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if viewModel.selectedQuestions.isEmpty {
                        Text("No questions selected yet. Select questions from the Causes tab.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(viewModel.selectedQuestions.count) question\(viewModel.selectedQuestions.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                if !viewModel.selectedQuestions.isEmpty {
                    // Questions grouped by cause
                    ForEach(questionsByCause.keys.sorted(), id: \.self) { cause in
                        VStack(alignment: .leading, spacing: 12) {
                            // Cause header
                            Text(cause)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.horizontal)
                            
                            // Questions for this cause
                            ForEach(questionsByCause[cause] ?? [], id: \.id) { question in
                                QuestionItemView(question: question)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        let askedCount = viewModel.selectedQuestions.filter { $0.isAsked }.count
                        let totalCount = viewModel.selectedQuestions.count
                        
                        Text("Progress")
                            .font(.headline)
                        
                        ProgressView(value: Double(askedCount), total: Double(totalCount))
                            .tint(.green)
                        
                        Text("\(askedCount) of \(totalCount) questions asked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct QuestionItemView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    let question: DoctorQuestion
    @State private var showingChat = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: {
                viewModel.toggleQuestionAsked(question)
            }) {
                Image(systemName: question.isAsked ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(question.isAsked ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Question text
            VStack(alignment: .leading, spacing: 4) {
                Text(question.question)
                    .font(.body)
                    .foregroundColor(question.isAsked ? .secondary : .primary)
                    .strikethrough(question.isAsked)
                
                // Show answer indicator if cached
                if let answers = question.answers, !answers.isEmpty {
                    Text("\(answers.count) answer\(answers.count == 1 ? "" : "s") cached")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Chat button
            Button(action: {
                showingChat = true
            }) {
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
                    .font(.body)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Remove button
            Button(action: {
                viewModel.removeQuestion(question)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.body)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .sheet(isPresented: $showingChat) {
            QuestionChatView(question: question)
                .environmentObject(viewModel)
        }
    }
}

struct QuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MedicalAssistantViewModel()
        viewModel.selectedQuestions = [
            DoctorQuestion(question: "What tests can confirm this diagnosis?", cause: "Migraine"),
            DoctorQuestion(question: "Are there preventive medications?", cause: "Migraine", isAsked: true),
            DoctorQuestion(question: "What lifestyle changes should I make?", cause: "Hypertension")
        ]
        
        return QuestionsView()
            .environmentObject(viewModel)
    }
}
