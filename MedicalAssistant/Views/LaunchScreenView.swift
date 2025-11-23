//
//  LaunchScreenView.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var showLaunchOverlay = true
    @State private var scale: CGFloat = 0.1
    @State private var backgroundOpacity: Double = 1.0
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        ZStack {
            // 1. Main Content Layer - Always present to avoid stutter
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(authService)
            
            // 2. Launch Screen Overlay Layer
            if showLaunchOverlay {
                ZStack {
                    // Background
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .opacity(backgroundOpacity)
                    
                    // Icon
                    Image("BarBarikIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .opacity(0.8)
                }
                .onAppear {
                    // Start expansion immediately
                    withAnimation(.easeIn(duration: 3.5)) {
                        scale = 15.0
                    }
                    
                    // At 2.0s: Fade out background
                    // Started earlier to ensure seamless transition while image is expanding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            backgroundOpacity = 0.0
                        }
                    }
                    
                    // At 3.5s: Remove overlay completely
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        showLaunchOverlay = false
                    }
                }
            }
        }
    }
}
