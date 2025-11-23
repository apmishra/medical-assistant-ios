# Firebase Authentication Setup Guide

This guide will help you set up Google and Facebook authentication for the Medical Assistant iOS app.

## Prerequisites

- Xcode 14.0 or later
- iOS 15.0 or later deployment target  
- An Apple Developer account
- A Google Cloud Platform account
- A Facebook Developer account

## Step 1: Add Firebase SDK Packages

1. Open `MedicalAssistant.xcodeproj` in Xcode
2. Go to **File** > **Add Package Dependencies**
3. Add Firebase iOS SDK: `https://github.com/firebase/firebase-ios-sdk`
4. Select these packages:
   - **FirebaseAuth**
   - **FirebaseCore**
5. Add Google Sign-In: `https://github.com/google/GoogleSignIn-iOS`
6. Add Facebook SDK: `https://github.com/facebook/facebook-ios-sdk`
   - Select **FacebookLogin** package

## Step 2: Configure Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add iOS app with bundle ID: `com.barbarik.MedicalAssistant`
4. Download `GoogleService-Info.plist` and replace the placeholder file
5. Enable **Google** and **Facebook** authentication in Firebase Console

## Step 3: Configure Info.plist

Add URL schemes and Facebook configuration to Info.plist.

## Step 4: Uncomment Firebase Code

Uncomment the Firebase imports and implementation code in:
- `AuthenticationService.swift`
- `MedicalAssistantApp.swift`

See FIREBASE_SETUP.md for detailed instructions.
