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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
