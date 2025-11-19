//
//  SolutionsView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct SolutionsView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Disclaimer
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Important Notice")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("This information is for educational purposes only and is NOT medical advice. Treatment options shown are based on general information available on the internet. Always consult healthcare professionals before starting any treatment.")
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

                // Solutions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Treatment Solutions")
                        .font(.title2)
                        .bold()

                    if let solutions = viewModel.solutions {
                        VStack(spacing: 20) {
                            ForEach(solutions.solutions) { category in
                                SolutionCategoryView(category: category)
                            }
                        }
                    } else {
                        Text("No solutions available yet. Please analyze causes first.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }
}

struct SolutionCategoryView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    let category: SolutionCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(category.category)
                .font(.title3)
                .bold()
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                ForEach(Array(category.treatments.enumerated()), id: \.element.id) { index, treatment in
                    TreatmentCard(treatment: treatment, categoryIndex: category.id.uuidString, treatmentIndex: index)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TreatmentCard: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    let treatment: Treatment
    let categoryIndex: String
    let treatmentIndex: Int

    private var sourceKey: String {
        "\(categoryIndex)-\(treatmentIndex)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(treatment.name)
                .font(.headline)

            Text(treatment.description)
                .font(.body)
                .foregroundColor(.secondary)

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

            // Recommended Questions Toggle
            Button(action: {
                viewModel.toggleSourceExpansion(sourceKey)
            }) {
                HStack {
                    Image(systemName: viewModel.expandedSources.contains(sourceKey) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                    Text(viewModel.expandedSources.contains(sourceKey) ? "Hide Recommended Questions" : "Show Recommended Questions")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }

            if viewModel.expandedSources.contains(sourceKey) {
                VStack(spacing: 8) {
                    ForEach(treatment.recommendedQuestions, id: \.self) { question in
                        Text(question)
                            .font(.caption)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }

            // Chat Button
            Button(action: {
                viewModel.startChat(with: treatment)
            }) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Chat About This Treatment")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
