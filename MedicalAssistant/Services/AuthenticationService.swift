//
//  AuthenticationService.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import Foundation
import SwiftUI

// MARK: - Firebase Imports
// TODO: Uncomment after adding Firebase SDK packages
// import FirebaseAuth
// import GoogleSignIn
// import FacebookLogin

class AuthenticationService: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String?
    @Published var currentProvider: String?
    @Published var isLoading: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let authKey = "isAuthenticated"
    private let userIdKey = "authUserId"
    private let providerKey = "authProvider"
    
    override init() {
        super.init()
        self.isAuthenticated = userDefaults.bool(forKey: authKey)
        self.userId = userDefaults.string(forKey: userIdKey)
        self.currentProvider = userDefaults.string(forKey: providerKey)
        
        // TODO: Uncomment after adding Firebase SDK
        // setupFirebaseAuthListener()
    }
    
    // MARK: - Firebase Auth Listener
    // TODO: Uncomment after adding Firebase SDK
    /*
    private func setupFirebaseAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.userId = user?.providerData.first?.providerID ?? "Unknown"
                self?.currentProvider = user?.providerData.first?.providerID ?? "Unknown"
                self?.saveState()
            }
        }
    }
    */
    
    // MARK: - Google Sign-In
    func signInWithGoogle() {
        #if DEBUG
        // Simulated authentication for development/testing without Firebase
        print("⚠️ Using simulated Google Sign-In")
        print("📋 To use real authentication, add Firebase SDK and uncomment the code below")

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            self?.isAuthenticated = true
            self?.userId = "google_user_\(UUID().uuidString.prefix(8))"
            self?.currentProvider = "Google"
            self?.saveState()
        }
        #else
        // Production code - uncomment after adding Firebase SDK
        // TODO: Uncomment the code below after adding Firebase SDK packages
        /*
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Error: Firebase not configured")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Error: Could not find root view controller")
            return
        }

        isLoading = true

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    return
                }

                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self?.isLoading = false
                    print("❌ Error: Could not get user credentials")
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )

                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        self?.isLoading = false

                        if let error = error {
                            print("❌ Firebase auth error: \(error.localizedDescription)")
                            return
                        }

                        if let firebaseUser = authResult?.user {
                            print("✅ Successfully signed in with Google")
                            self?.isAuthenticated = true
                            self?.userId = firebaseUser.uid
                            self?.currentProvider = "Google"
                            self?.saveState()
                        }
                    }
                }
            }
        }
        */
        print("⚠️ Production Google Sign-In not yet configured")
        print("📋 See FIREBASE_SETUP.md for setup instructions")
        #endif
    }
    
    // MARK: - Facebook Login
    func signInWithFacebook() {
        #if DEBUG
        // Simulated authentication for development/testing without Firebase
        print("⚠️ Using simulated Facebook Login")
        print("📋 To use real authentication, add Firebase SDK and Facebook SDK, then uncomment the code below")

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            self?.isAuthenticated = true
            self?.userId = "facebook_user_\(UUID().uuidString.prefix(8))"
            self?.currentProvider = "Facebook"
            self?.saveState()
        }
        #else
        // Production code - uncomment after adding Firebase SDK and Facebook SDK
        // TODO: Uncomment the code below after adding Firebase SDK packages
        /*
        let loginManager = LoginManager()
        isLoading = true

        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    print("❌ Facebook login error: \(error.localizedDescription)")
                    return
                }

                guard let result = result, !result.isCancelled else {
                    self?.isLoading = false
                    print("⚠️ Facebook login cancelled by user")
                    return
                }

                guard let tokenString = AccessToken.current?.tokenString else {
                    self?.isLoading = false
                    print("❌ Error: Could not get Facebook access token")
                    return
                }

                let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)

                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        self?.isLoading = false

                        if let error = error {
                            print("❌ Firebase auth error: \(error.localizedDescription)")
                            return
                        }

                        if let firebaseUser = authResult?.user {
                            print("✅ Successfully signed in with Facebook")
                            self?.isAuthenticated = true
                            self?.userId = firebaseUser.uid
                            self?.currentProvider = "Facebook"
                            self?.saveState()
                        }
                    }
                }
            }
        }
        */
        print("⚠️ Production Facebook Login not yet configured")
        print("📋 See FIREBASE_SETUP.md for setup instructions")
        #endif
    }
    
    // MARK: - Legacy Method (for backward compatibility)
    func signIn(provider: String, username: String, password: String) {
        // Check if switching providers - auto logout
        if isAuthenticated && currentProvider != provider {
            signOut()
        }
        
        // Validate credentials (simulated - accept any non-empty)
        guard !username.isEmpty && !password.isEmpty else {
            return
        }
        
        // Route to appropriate sign-in method
        if provider == "Google" {
            signInWithGoogle()
        } else if provider == "Facebook" {
            signInWithFacebook()
        } else {
            // Fallback simulated auth
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.isLoading = false
                self?.isAuthenticated = true
                self?.userId = provider
                self?.currentProvider = provider
                self?.saveState()
            }
        }
    }
    
    func signOut() {
        print("🚪 Signing out user: \(userId ?? "unknown")")

        // TODO: Uncomment after adding Firebase SDK
        /*
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            LoginManager().logOut()
            print("✅ Successfully signed out from Firebase and social providers")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
        */

        self.isAuthenticated = false
        self.userId = nil
        self.currentProvider = nil
        saveState()
    }
    
    func continueAsGuest() {
        self.isAuthenticated = true
        self.userId = "Guest"
        self.currentProvider = "Guest"
        saveState()
    }
    
    private func saveState() {
        userDefaults.set(isAuthenticated, forKey: authKey)
        userDefaults.set(userId, forKey: userIdKey)
        userDefaults.set(currentProvider, forKey: providerKey)
    }
}



