# Medical Assistant iOS

A native iOS application that helps analyze medical documents and provides information about potential symptoms, causes, and treatment options using Claude AI.

## Overview

This iOS app is a conversion of the web-based Medical Assistant application to a native iOS experience using SwiftUI. It provides the same powerful features in a mobile-first interface:

- **PDF Upload & Analysis**: Upload medical reports and extract relevant information
- **Symptom Extraction**: AI-powered analysis to identify symptoms from medical data
- **Cause Identification**: Get potential medical causes based on confirmed symptoms
- **Treatment Solutions**: Explore treatment options across multiple medical approaches (Ayurvedic, Homeopathic, Allopathic, Naturopathic)
- **Interactive Chat**: Ask questions about specific treatments
- **Debug Logging**: Monitor API calls and application behavior

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- A Claude API key from Anthropic

## Project Structure

```
MedicalAssistant/
├── MedicalAssistantApp.swift          # App entry point
├── Models/
│   └── MedicalModels.swift            # Data models
├── Views/
│   ├── ContentView.swift              # Main tab navigation
│   ├── UploadView.swift               # PDF upload & manual entry
│   ├── SymptomsView.swift             # Symptom selection
│   ├── CausesView.swift               # Potential causes display
│   ├── SolutionsView.swift            # Treatment solutions
│   ├── SettingsView.swift             # API key configuration
│   ├── DebugView.swift                # Debug logs
│   ├── ChatView.swift                 # Treatment chat interface
│   └── APIKeyInputView.swift          # API key input modal
├── ViewModels/
│   └── MedicalAssistantViewModel.swift # Main view model
├── Services/
│   └── ClaudeAPIService.swift         # Claude API integration
└── Resources/
    └── Info.plist                      # App configuration

MedicalAssistant.xcodeproj/            # Xcode project file
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/apmishra/medical-assistant-ios.git
cd medical-assistant-ios
```

### 2. Open in Xcode

```bash
open MedicalAssistant.xcodeproj
```

### 3. Configure Your Development Team

1. Select the `MedicalAssistant` project in the Project Navigator
2. Select the `MedicalAssistant` target
3. Go to the "Signing & Capabilities" tab
4. Select your development team from the dropdown

### 4. Build and Run

1. Select a simulator or connected device
2. Press `Cmd + R` to build and run
3. On first launch, you'll be prompted to enter your Claude API key

### 5. Get a Claude API Key

If you don't have a Claude API key:

1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to API Keys
4. Create a new API key
5. Copy the key and paste it into the app

## Features

### 📄 Upload Medical Documents

- Support for PDF files
- Manual text entry option
- AI-powered text extraction from PDFs

### 🔍 Symptom Analysis

- Automatic symptom extraction from medical data
- Severity classification (mild, moderate, severe)
- Source tracking for each symptom
- Manual symptom addition

### 🏥 Cause Identification

- AI-powered analysis of potential medical conditions
- Probability ratings (high, medium, low)
- Urgency levels (immediate, soon, routine)
- Detailed explanations for each potential cause

### 💊 Treatment Solutions

- Multiple medical approaches:
  - Ayurvedic
  - Homeopathic
  - Allopathic
  - Naturopathic
- Source citations with links
- Recommended questions for each treatment
- Interactive chat to learn more

### 💬 Interactive Chat

- Ask specific questions about treatments
- Context-aware responses
- Full conversation history

### ⚙️ Settings

- Secure API key storage
- API key status indicator
- App information and disclaimers

### 🐛 Debug Logs

- Real-time logging of all API calls
- Error tracking
- System information display
- Token usage monitoring

## Architecture

### MVVM Pattern

The app follows the Model-View-ViewModel (MVVM) architecture pattern:

- **Models**: Pure data structures (Symptom, MedicalCause, Treatment, etc.)
- **Views**: SwiftUI views that display data and handle user interaction
- **ViewModels**: Business logic and state management
- **Services**: API communication and data processing

### Data Flow

1. User interacts with Views
2. Views communicate with ViewModel
3. ViewModel uses Services to fetch/process data
4. Services communicate with Claude API
5. Results flow back through ViewModel to Views
6. Views update automatically via SwiftUI's reactive bindings

## API Integration

The app communicates directly with Anthropic's Claude API:

- Endpoint: `https://api.anthropic.com/v1/messages`
- Model: `claude-sonnet-4-20250514`
- API Key stored securely in UserDefaults
- All network calls are async/await
- Proper error handling and logging

## Security & Privacy

### API Key Storage

- API keys are stored locally in UserDefaults
- Keys are never transmitted to any server except Anthropic's official API
- No third-party analytics or tracking

### Network Security

- All API calls use HTTPS with TLS 1.2+
- App Transport Security (ATS) enabled
- Only allows connections to api.anthropic.com

### Data Privacy

- No user data is stored on external servers
- All medical information stays on the device
- PDF processing happens locally before API analysis

## Medical Disclaimer

⚠️ **IMPORTANT**: This application is for informational and educational purposes only.

- This app is **NOT** a substitute for professional medical advice, diagnosis, or treatment
- Information provided is AI-generated and may contain errors
- Always seek the advice of qualified healthcare providers
- Never disregard professional medical advice based on information from this app
- In case of medical emergency, contact emergency services immediately

## Dependencies

This is a pure SwiftUI application with no external dependencies. It uses only Apple's native frameworks:

- SwiftUI - UI framework
- Foundation - Core functionality
- UniformTypeIdentifiers - File type handling

## Development

### Building for Release

1. Update version and build numbers in project settings
2. Archive the app: `Product > Archive`
3. Distribute through App Store Connect or TestFlight

### Testing

The app can be tested on:
- iOS Simulator (iPhone, iPad)
- Physical devices (requires Apple Developer account)

### Customization

To customize the app:

- **Model**: Change in `ClaudeAPIService.swift`
- **System Prompt**: Modify in `ClaudeAPIService.swift`
- **UI Colors**: Update in respective View files
- **App Icon**: Add to Assets catalog

## Troubleshooting

### API Key Issues

- Ensure your API key starts with `sk-ant-`
- Check that you have available credits in your Anthropic account
- Verify your API key in Settings tab

### PDF Upload Issues

- Ensure the file is a valid PDF
- Check file permissions
- Try using manual text entry as an alternative

### Network Errors

- Check your internet connection
- Verify you can reach api.anthropic.com
- Check debug logs for detailed error messages

## Contributing

This is a conversion of the original web-based Medical Assistant. For contributions:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

See LICENSE file for details.

## Original Project

This iOS app is based on the web application:
- Original Repo: https://github.com/apmishra/medical-assistant
- Web Version: React-based medical assistant with Express backend

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review debug logs for error details

## Acknowledgments

- Powered by Claude AI from Anthropic
- Built with SwiftUI by Apple
- Converted from the original React web application

---

**Version**: 1.0
**Last Updated**: 2025
**Platform**: iOS 16.0+
**Language**: Swift 5.9+
