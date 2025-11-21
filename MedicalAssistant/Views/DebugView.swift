//
//  DebugView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Debug Logs")
                    .font(.title2)
                    .bold()

                Spacer()

                Button(action: {
                    viewModel.clearDebugLogs()
                }) {
                    Text("Clear Logs")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()

            // Logs
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.debugLogs.isEmpty {
                        Text("No debug logs yet...")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.debugLogs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("[\(log.timestamp)]")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)

                                    Text(log.message)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(logColor(for: log.type))
                                }
                                
                                if let input = log.inputTokens, let output = log.outputTokens {
                                    Text("Tokens: \(input) in / \(output) out")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.black)
            .cornerRadius(8)
            .padding(.horizontal)

            Divider()

            // System Information
            VStack(alignment: .leading, spacing: 12) {
                Text("System Information")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    InfoRow(label: "API Key Status", value: viewModel.apiKey.isEmpty ? "Not Configured" : "Configured", valueColor: viewModel.apiKey.isEmpty ? .red : .green)
                    InfoRow(label: "Total API Calls", value: "\(viewModel.debugLogs.filter { $0.message.contains("API call") }.count)")
                    InfoRow(label: "Errors", value: "\(viewModel.debugLogs.filter { $0.type == .error }.count)")
                    InfoRow(label: "Model", value: "claude-sonnet-4-20250514")
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    private func logColor(for type: DebugLog.LogType) -> Color {
        switch type {
        case .info: return .gray
        case .success: return .green
        case .warning: return .yellow
        case .error: return .red
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundColor(valueColor)
        }
    }
}
