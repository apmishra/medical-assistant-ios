//
//  HomeView.swift
//  MedicalAssistant
//
//  Created by Barbarik
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @EnvironmentObject var authService: AuthenticationService
    @State private var showSessions = false
    
    var providerSessions: [MedicalSession] {
        guard let provider = authService.userId else { return [] }
        return viewModel.sessions.filter { $0.authProvider == provider }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo and Welcome
            VStack(spacing: 20) {
                Image(systemName: "cross.case.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Welcome")
                    .font(.largeTitle)
                    .bold()
                
                if let provider = authService.userId {
                    Text("Logged in with \(provider)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 40)
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.createNewSession(provider: authService.userId ?? "Unknown")
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
                
                if !providerSessions.isEmpty {
                    Button(action: {
                        showSessions = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("View Previous Sessions (\(providerSessions.count))")
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
            }
            
            Spacer()
            
            // Logout Button
            Button(action: {
                viewModel.clearCurrentSession()
                authService.signOut()
            }) {
                Text("Log Out")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .padding(.bottom, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.85)
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
