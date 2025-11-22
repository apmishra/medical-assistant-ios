//
//  LoginView.swift
//  MedicalAssistant
//
//  Created by Barbarik
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var showCredentialsPrompt = false
    @State private var username = ""
    @State private var password = ""
    @State private var selectedProvider = ""
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Close button if presented modally
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    Spacer()
                }
                
                Spacer()
                
                // Logo Section
                VStack(spacing: 20) {
                    Image(systemName: "cross.case.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Barbarik")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Medical Assistant")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Auth Buttons
                VStack(spacing: 16) {
                    if authService.isLoading {
                        ProgressView("Authenticating...")
                            .scaleEffect(1.2)
                            .padding()
                    } else {
                        // Continue Without Login (Guest Mode)
                        Button(action: {
                            authService.continueAsGuest()
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                Text("Continue Without Login")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray4))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        
                        // Google
                        SocialLoginButton(
                            title: "Continue with Google",
                            imageName: "g.circle.fill", // System image as placeholder
                            backgroundColor: .white,
                            foregroundColor: .black,
                            borderColor: .gray.opacity(0.3)
                        ) {
                            authService.signInWithGoogle()
                        }
                        
                        // Facebook
                        SocialLoginButton(
                            title: "Continue with Facebook",
                            imageName: "f.circle.fill", // System image as placeholder
                            backgroundColor: Color(red: 0.09, green: 0.47, blue: 0.95), // FB Blue
                            foregroundColor: .white
                        ) {
                            authService.signInWithFacebook()
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Text("By continuing, you agree to our Terms & Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
}

struct SocialLoginButton: View {
    let title: String
    let imageName: String
    let backgroundColor: Color
    let foregroundColor: Color
    var borderColor: Color = .clear
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }
}
