//
//  CausesView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct CausesView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Disclaimer
                    DisclaimerBanner()

                    // Potential Causes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Potential Causes")
                            .font(.title2)
                            .bold()

                        if let causes = viewModel.potentialCauses {
                            VStack(spacing: 12) {
                                ForEach(causes.causes) { cause in
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            viewModel.toggleCause(cause)
                                        }) {
                                            Image(systemName: viewModel.selectedCauses.contains(cause) ? "checkmark.square.fill" : "square")
                                                .font(.title2)
                                                .foregroundColor(viewModel.selectedCauses.contains(cause) ? .blue : .gray)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        NavigationLink(destination: CauseTreatmentsView(cause: cause)
                                            .environmentObject(viewModel)) {
                                            CauseCard(cause: cause)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("No analysis available yet. Please analyze symptoms first.")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }

                }
                .padding()
            }
            .navigationTitle("Causes")
        }
    }
}

struct DisclaimerBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Medical Disclaimer")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("This information is AI-generated and NOT a substitute for professional medical advice. Always consult qualified healthcare providers for proper diagnosis and treatment.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CauseCard: View {
    let cause: MedicalCause

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(cause.condition)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    ProbabilityBadge(probability: cause.probability)
                    UrgencyBadge(urgency: cause.urgency)
                }
            }

            Text(cause.explanation)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProbabilityBadge: View {
    let probability: MedicalCause.Probability

    var body: some View {
        Text("\(probability.rawValue) probability")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
    }

    private var backgroundColor: Color {
        switch probability {
        case .high: return .red.opacity(0.2)
        case .medium: return .yellow.opacity(0.2)
        case .low: return .green.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch probability {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct UrgencyBadge: View {
    let urgency: MedicalCause.Urgency

    var body: some View {
        Text(urgency.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
    }

    private var backgroundColor: Color {
        switch urgency {
        case .immediate: return .red.opacity(0.2)
        case .soon: return .orange.opacity(0.2)
        case .routine: return .blue.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch urgency {
        case .immediate: return .red
        case .soon: return .orange
        case .routine: return .blue
        }
    }
}
