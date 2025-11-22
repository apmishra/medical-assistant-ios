# Firebase Authentication Setup Guide

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Enter project name (e.g., "Medical Assistant")
4. Follow the setup wizard

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter Bundle ID: `com.barbarik.MedicalAssistant`
3. Download `GoogleService-Info.plist`
4. **IMPORTANT**: Replace the placeholder file at:
   `/Users/aditya.mishra/src/medical-assistant-ios/MedicalAssistant/GoogleService-Info.plist`
   with your downloaded file

## Step 3: Enable Authentication Providers

### Google Sign-In
1. In Firebase Console → Authentication → Sign-in method
2. Click "Google" → Enable
3. Add support email
4. Save

### Facebook Login
1. Go to https://developers.facebook.com
2. Create a new app
3. Get App ID and App Secret
4. In Firebase Console → Authentication → Sign-in method
5. Click "Facebook" → Enable
6. Enter Facebook App ID and App Secret
7. Copy the OAuth redirect URI from Firebase
8. Add it to Facebook app settings

## Step 4: Add Firebase SDK via Xcode

1. Open `MedicalAssistant.xcodeproj` in Xcode
2. File → Add Package Dependencies
3. Enter: `https://github.com/firebase/firebase-ios-sdk`
4. Select version 10.x or latest
5. Add these packages:
   - FirebaseAuth
   - FirebaseCore
   - GoogleSignIn
   - FacebookLogin (or use Firebase Facebook provider)

## Step 5: Update Info.plist

The code will automatically add required URL schemes and configurations.

## Step 6: Test

1. Build and run the app
2. Try logging in with Google
3. Try logging in with Facebook
4. Verify sessions are created with correct provider tags

## Troubleshooting

- **"GoogleService-Info.plist not found"**: Make sure you replaced the placeholder file
- **"No such module 'FirebaseAuth'"**: Add Firebase packages via SPM
- **Google Sign-In fails**: Check REVERSED_CLIENT_ID in Info.plist matches Firebase
- **Facebook Login fails**: Verify Facebook App ID in Info.plist and Firebase Console
