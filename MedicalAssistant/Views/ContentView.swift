//
//  ContentView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        ZStack {
            // Main App Content (Always rendered, but maybe hidden/disabled if no session)
            NavigationView {
                VStack(spacing: 0) {
                    // Tab Selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            TabButton(title: "Symptoms", icon: "arrow.up.doc", isSelected: viewModel.selectedTab == 0) {
                                viewModel.selectedTab = 0
                            }
                            TabButton(title: "Confirm", icon: "list.bullet.clipboard", isSelected: viewModel.selectedTab == 1) {
                                viewModel.selectedTab = 1
                            }
                            TabButton(title: "Causes", icon: "cross.case", isSelected: viewModel.selectedTab == 2) {
                                viewModel.selectedTab = 2
                            }
                            TabButton(title: "Treatments", icon: "pills.fill", isSelected: viewModel.selectedTab == 3) {
                                viewModel.selectedTab = 3
                            }
                            TabButton(title: "Settings", icon: "gearshape.fill", isSelected: viewModel.selectedTab == 4) {
                                viewModel.selectedTab = 4
                            }
                            TabButton(title: "Debug", icon: "ladybug.fill", isSelected: viewModel.selectedTab == 5) {
                                viewModel.selectedTab = 5
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    Divider()
                        .padding(.top, 8)
                    
                    // Content Area
                    ZStack {
                        switch viewModel.selectedTab {
                        case 0: UploadView()
                        case 1: SymptomsView()
                        case 2: CausesView()
                        case 3: TreatmentsView()
                        case 4: SettingsView()
                        case 5: DebugView()
                        default: UploadView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text(currentTabTitle)
                            .font(.title2)
                            .bold()
                            .fixedSize()
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button(action: {
                                viewModel.clearCurrentSession()
                            }) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }

                            Button(action: {
                                viewModel.createNewSession()
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .disabled(viewModel.currentSessionId == nil) // Disable interaction when home/splash is shown
            
            // Splash Overlay
            if viewModel.currentSessionId == nil {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .sheet(isPresented: $viewModel.showApiKeyInput) {
            APIKeyInputView()
        }
        .sheet(item: $viewModel.activeChatTreatment) { treatment in
            ChatView(treatment: treatment)
                .environmentObject(viewModel)
        }
        .sheet(item: $viewModel.activeChatSymptom) { symptom in
            SymptomChatView(symptom: symptom)
                .environmentObject(viewModel)
        }
        .sheet(item: $viewModel.activeChatCause) { cause in
            CauseChatView(cause: cause)
                .environmentObject(viewModel)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }

    var currentTabTitle: String {
        switch viewModel.selectedTab {
        case 0: return "Symptoms"
        case 1: return "Confirm"
        case 2: return "Causes"
        case 3: return "Treatments"
        case 4: return "Settings"
        case 5: return "Debug"
        default: return ""
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption)
                    .fixedSize()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .blue : .gray)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? .blue : .clear),
                alignment: .bottom
            )
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Processing...")
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}
