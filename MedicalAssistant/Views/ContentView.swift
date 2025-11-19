//
//  ContentView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        TabButton(title: "Upload", icon: "arrow.up.doc", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        TabButton(title: "Symptoms", icon: "list.bullet.clipboard", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        TabButton(title: "Causes", icon: "cross.case", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                        TabButton(title: "Solutions", icon: "heart.text.square", isSelected: selectedTab == 3) {
                            selectedTab = 3
                        }
                        TabButton(title: "Settings", icon: "gear", isSelected: selectedTab == 4) {
                            selectedTab = 4
                        }
                        TabButton(title: "Debug", icon: "ladybug", isSelected: selectedTab == 5) {
                            selectedTab = 5
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 50)
                .background(Color(.systemBackground))

                Divider()

                // Tab Content
                TabView(selection: $selectedTab) {
                    UploadView()
                        .tag(0)
                    SymptomsView()
                        .tag(1)
                    CausesView()
                        .tag(2)
                    SolutionsView()
                        .tag(3)
                    SettingsView()
                        .tag(4)
                    DebugView()
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Medical Assistant")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $viewModel.showApiKeyInput) {
            APIKeyInputView()
        }
        .sheet(item: $viewModel.activeChatTreatment) { treatment in
            ChatView(treatment: treatment)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
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
            }
            .frame(maxWidth: .infinity)
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
