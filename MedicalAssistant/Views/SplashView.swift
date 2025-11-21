//
//  SplashView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var showSessions = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "cross.case.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text("AI Opinion")
                .font(.largeTitle)
                .bold()

            Text("General Findings")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                viewModel.createNewSession()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Start New Session")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            if !viewModel.sessions.isEmpty {
                Button(action: {
                    showSessions = true
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View Previous Sessions")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85) // Adjust opacity to make it more translucent
        )
        .ignoresSafeArea()
        .sheet(isPresented: $showSessions) {
            NavigationView {
                SessionsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showSessions = false
                            }
                        }
                    }
            }
        }
    }
}
