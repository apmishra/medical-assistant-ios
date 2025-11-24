//
//  QuestionChatView.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import SwiftUI

struct QuestionChatView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    let question: DoctorQuestion
    @State private var answers: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(question.question)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("About: \(question.cause)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Answers Section
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Fetching answers...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if !answers.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Answers")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if let lastFetched = question.lastFetched {
                                    Text("Updated \(timeAgo(from: lastFetched))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                    
                                    Text(answer)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Question Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        fetchAnswers(refresh: true)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if let cachedAnswers = question.answers, !cachedAnswers.isEmpty {
                    answers = cachedAnswers
                } else {
                    fetchAnswers()
                }
            }
        }
    }
    
    private func fetchAnswers(refresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedAnswers = try await viewModel.fetchAnswersForQuestion(question, refresh: refresh)
                await MainActor.run {
                    answers = fetchedAnswers
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch answers: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
