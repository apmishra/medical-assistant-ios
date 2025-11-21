//
//  SymptomChatView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct SymptomChatView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @Environment(\.dismiss) var dismiss
    let symptom: Symptom

    @State private var messageText: String = ""
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.chatMessages[symptom.symptom] ?? []) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: viewModel.chatMessages[symptom.symptom]?.count) { _ in
                        scrollToBottom()
                    }
                }

                Divider()

                // Input
                HStack(spacing: 12) {
                    TextField("Ask a question about this symptom...", text: $messageText)
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
            .navigationTitle(symptom.symptom)
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
            await viewModel.sendSymptomChatMessage(message)
        }
    }

    private func scrollToBottom() {
        guard let messages = viewModel.chatMessages[symptom.symptom],
              let lastMessage = messages.last,
              let proxy = scrollProxy else { return }

        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}
