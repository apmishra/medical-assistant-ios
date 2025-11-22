//
//  ChatView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @Environment(\.dismiss) var dismiss
    let treatment: Treatment

    @State private var messageText: String = ""
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.chatMessages[treatment.name] ?? []) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: viewModel.chatMessages[treatment.name]?.count) { _ in
                        scrollToBottom()
                    }
                }

                Divider()
                
                // Recommended Questions (if available and no messages sent yet)
                if !treatment.recommendedQuestions.isEmpty && (viewModel.chatMessages[treatment.name]?.count ?? 0) <= 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Questions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(treatment.recommendedQuestions, id: \.self) { question in
                                    Button(action: {
                                        messageText = question
                                    }) {
                                        Text(question)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    
                    Divider()
                }

                // Input
                HStack(spacing: 12) {
                    TextField("Ask a question about this treatment...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(messageText.isEmpty || viewModel.isLoading ? .gray : .blue)
                            .font(.title3)
                    }
                    .disabled(messageText.isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle(treatment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                        viewModel.closeChat()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let message = messageText
        messageText = ""

        Task {
            await viewModel.sendChatMessage(message)
        }
    }

    private func scrollToBottom() {
        guard let messages = viewModel.chatMessages[treatment.name],
              let lastMessage = messages.last,
              let proxy = scrollProxy else { return }

        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}
