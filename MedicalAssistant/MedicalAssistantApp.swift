//
//  MedicalAssistantApp.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

// MARK: - Firebase Imports
// TODO: Uncomment after adding Firebase SDK via Swift Package Manager
// import FirebaseCore
// import GoogleSignIn
// import FacebookCore

@main
struct MedicalAssistantApp: App {
    @StateObject private var viewModel = MedicalAssistantViewModel()
    @StateObject private var authService = AuthenticationService()

    init() {
        // TODO: Uncomment after adding Firebase SDK
        // FirebaseApp.configure()
        // ApplicationDelegate.shared.application(
        //     UIApplication.shared,
        //     didFinishLaunchingWithOptions: nil
        // )
    }

    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .environmentObject(viewModel)
                .environmentObject(authService)
                // TODO: Uncomment after adding Firebase SDK
                // .onOpenURL { url in
                //     GIDSignIn.sharedInstance.handle(url)
                //     ApplicationDelegate.shared.application(
                //         UIApplication.shared,
                //         open: url,
                //         sourceApplication: nil,
                //         annotation: [UIApplication.OpenURLOptionsKey.annotation]
                //     )
                // }
        }
    }
}
