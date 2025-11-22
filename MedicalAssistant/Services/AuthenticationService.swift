//
//  AuthenticationService.swift
//  MedicalAssistant
//
//  Created by Barbarik
//

import Foundation
import SwiftUI

// MARK: - Firebase Imports
// TODO: Add these packages via Swift Package Manager in Xcode:
// - Firebase/Auth
// - GoogleSignIn
// Uncomment the following lines after adding Firebase SDK:
// import FirebaseAuth
// import GoogleSignIn
// import FBSDKLoginKit

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
        // TODO: Implement Google Sign-In after adding Firebase SDK
        // This is a placeholder implementation
        print("⚠️ Google Sign-In requires Firebase SDK")
        print("📋 Follow instructions in FIREBASE_SETUP.md")
        
        // Simulated for now
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            self?.isAuthenticated = true
            self?.userId = "Google"
            self?.currentProvider = "Google"
            self?.saveState()
        }
        
        /* TODO: Uncomment after adding Firebase SDK
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        isLoading = true
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard error == nil else {
                self?.isLoading = false
                print("Google Sign-In error: \(error!.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                          accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                self?.isLoading = false
                if let error = error {
                    print("Firebase auth error: \(error.localizedDescription)")
                }
            }
        }
        */
    }
    
    // MARK: - Facebook Login
    func signInWithFacebook() {
        // TODO: Implement Facebook Login after adding Firebase SDK
        print("⚠️ Facebook Login requires Firebase SDK and Facebook SDK")
        print("📋 Follow instructions in FIREBASE_SETUP.md")
        
        // Simulated for now
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            self?.isAuthenticated = true
            self?.userId = "Facebook"
            self?.currentProvider = "Facebook"
            self?.saveState()
        }
        
        /* TODO: Uncomment after adding Firebase SDK and Facebook SDK
        let loginManager = LoginManager()
        isLoading = true
        
        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { [weak self] result, error in
            guard error == nil else {
                self?.isLoading = false
                print("Facebook login error: \(error!.localizedDescription)")
                return
            }
            
            guard let result = result, !result.isCancelled else {
                self?.isLoading = false
                return
            }
            
            guard let tokenString = AccessToken.current?.tokenString else {
                self?.isLoading = false
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                self?.isLoading = false
                if let error = error {
                    print("Firebase auth error: \(error.localizedDescription)")
                }
            }
        }
        */
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
        // TODO: Uncomment after adding Firebase SDK
        // try? Auth.auth().signOut()
        // GIDSignIn.sharedInstance.signOut()
        // LoginManager().logOut()
        
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



