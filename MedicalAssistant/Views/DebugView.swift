//
//  DebugView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var showCopiedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Debug Logs")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.debugLogs.removeAll()
                        viewModel.totalInputTokens = 0
                        viewModel.totalOutputTokens = 0
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                // Token Usage Summary Table
                VStack(alignment: .leading, spacing: 12) {
                    Text("Token Usage Summary")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        // Header Row
                        HStack {
                            Text("Type")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Count")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 100, alignment: .trailing)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        
                        Divider()
                        
                        // Input Tokens Row
                        HStack {
                            Text("Input Tokens")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(viewModel.totalInputTokens)")
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(width: 100, alignment: .trailing)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        
                        Divider()
                        
                        // Output Tokens Row
                        HStack {
                            Text("Output Tokens")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(viewModel.totalOutputTokens)")
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(width: 100, alignment: .trailing)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        
                        Divider()
                        
                        // Total Row
                        HStack {
                            Text("Total Tokens")
                                .font(.body)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(viewModel.totalInputTokens + viewModel.totalOutputTokens)")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .frame(width: 100, alignment: .trailing)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                    }
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Activity Logs Section
                Text("Activity Logs")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.debugLogs.isEmpty {
                    Text("No debug logs yet...")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.debugLogs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("[\(formatTimestamp(log.timestamp))]")
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
                            .textSelection(.enabled)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .medium
            return displayFormatter.string(from: date)
        }
        return timestamp
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
