//
//  MedicalAssistantApp.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

@main
struct MedicalAssistantApp: App {
    @StateObject private var viewModel = MedicalAssistantViewModel()
    @StateObject private var authService = AuthenticationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(authService)
        }
    }
}
