# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Building the Project
```bash
# Build the main app
xcodebuild -project AntiSocial.xcodeproj -scheme AntiSocial -configuration Debug build

# Build for release
xcodebuild -project AntiSocial.xcodeproj -scheme AntiSocial -configuration Release build

# Build and create IPA (for distribution)
xcode-project build-ipa --project "AntiSocial.xcodeproj" --scheme "AntiSocial"
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project AntiSocial.xcodeproj -scheme AntiSocialTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project AntiSocial.xcodeproj -scheme AntiSocial -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:AntiSocialUITests
```

### Managing Dependencies
```bash
# Resolve Swift Package Manager dependencies
xcodebuild -resolvePackageDependencies -project AntiSocial.xcodeproj

# Update package dependencies
xcodebuild -project AntiSocial.xcodeproj -scheme AntiSocial -resolvePackageDependencies
```

## Architecture Overview

### Project Structure
This is a Screen Time/Digital Wellbeing iOS application built with SwiftUI and modern Swift concurrency. The app helps users monitor and control their app usage through Apple's Family Controls framework.

### Key Components

1. **Main App** (`AntiSocial/`)
   - **App/**: Application entry point and configuration
   - **Models/**: Data models for app blocking, device activity, and user data
   - **Screens/**: Feature-based UI organization (Login, Onboarding, AppMonitor, Profile, Notifications)
   - **Utilities/**: Core services, extensions, and managers
   - **Views/**: Reusable UI components

2. **App Extensions**
   - **DeviceActivityMonitorExtension**: Monitors device activity in the background
   - **DeviceReportExtension**: Generates device activity reports
   - **Shield**: Displays shield UI when blocked apps are accessed

3. **Core Services**
   - **Authentication**: Google Sign-In and Apple Sign-In via `AuthenticationViewModel`
   - **Device Activity**: App blocking and monitoring via `DeviceActivityService` and `FamilyControlsManager`
   - **Storage**: Dual storage system using GRDB (local) and Firestore (cloud)
   - **Subscriptions**: RevenueCat integration via `SubscriptionManager`
   - **Notifications**: Local notifications and Darwin notifications for cross-extension communication

### Data Flow
1. User authentication through OAuth providers
2. App usage data collected via DeviceActivityMonitor extension
3. Data stored locally in GRDB and synced to Firestore
4. Shield extension activated when user attempts to open blocked apps
5. Darwin notifications used for real-time communication between app and extensions

### Key Dependencies
- **Firebase**: Authentication, Firestore, Analytics, Crashlytics
- **RevenueCat**: Subscription management
- **GRDB**: Local SQLite database
- **Google Sign-In**: OAuth authentication
- **Family Controls**: Apple's screen time management framework

### Development Notes
- The app uses App Groups (`group.com.app.antisocial`) for data sharing between extensions
- Firebase configuration is in `GoogleService-Info.plist`
- CI/CD is configured via Codemagic (see `codemagic.yaml`)
- No linting or formatting tools are currently configured
- Test coverage is minimal - expand tests when adding new features

### Extension Communication
Extensions communicate with the main app through:
- App Groups shared container
- Darwin notifications (see `DarwinNotificationManager`)
- Shared GRDB database in the app group container