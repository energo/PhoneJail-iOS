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

# Clean build folder
xcodebuild clean -project AntiSocial.xcodeproj -scheme AntiSocial

# Build specific target with destination
xcodebuild -project AntiSocial.xcodeproj -scheme AntiSocial -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project AntiSocial.xcodeproj -scheme AntiSocialTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project AntiSocial.xcodeproj -scheme AntiSocial -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:AntiSocialUITests

# Run specific test
xcodebuild test -project AntiSocial.xcodeproj -scheme AntiSocialTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:AntiSocialTests/TestClassName/testMethodName
```

### Managing Dependencies
```bash
# Resolve Swift Package Manager dependencies
xcodebuild -resolvePackageDependencies -project AntiSocial.xcodeproj

# Clean derived data (when experiencing build issues)
rm -rf ~/Library/Developer/Xcode/DerivedData/AntiSocial-*

# Reset package caches (in Xcode: File → Packages → Reset Package Caches)
```

### CI/CD (Codemagic)
```bash
# Increment build number (used in CI)
LATEST_BUILD_NUMBER=$(app-store-connect get-latest-testflight-build-number "6747712365")
NEW_BUILD_NUMBER=$(($LATEST_BUILD_NUMBER + 1))
agvtool new-version -all $NEW_BUILD_NUMBER
```

## Architecture Overview

### Core Architecture Pattern
The app follows a **modular architecture with app extensions**, leveraging Apple's Screen Time and Family Controls frameworks. Key patterns:
- **Main App**: SwiftUI with MVVM pattern
- **Service Layer**: Singleton services for shared functionality
- **App Extensions**: Three sandboxed extensions for Screen Time features
- **Dual Storage**: Local-first (GRDB) with cloud sync (Firestore)

### SwiftUI Architecture Philosophy

#### Singleton Services as Environment Objects
The project uses singleton services injected through SwiftUI's environment system:

```swift
// In AntiSocialApp.swift
@StateObject private var authVM = AuthenticationViewModel(subscriptionManager: SubscriptionManager.shared)
@StateObject private var subscriptionManager = SubscriptionManager.shared
@StateObject private var deviceActivityService = DeviceActivityService.shared
@StateObject private var familyControlsManager = FamilyControlsManager.shared

// Injected via environment
.environmentObject(authVM)
.environmentObject(subscriptionManager)
.environmentObject(deviceActivityService)
.environmentObject(familyControlsManager)
```

**Benefits of this approach:**
- Centralized state management
- Easy dependency injection
- Consistent access across view hierarchy
- Memory-efficient singleton pattern

#### MVVM Architecture with ViewModels and Services
This project follows a **MVVM (Model-View-ViewModel)** pattern, combining ViewModels for business logic with singleton services for shared functionality:

**Core Principles:**
- **ViewModels for Business Logic**: Each complex screen has its own ViewModel (e.g., `AuthenticationViewModel`, `AppMonitorViewModel`)
- **Services as Singletons**: Shared functionality implemented as singleton services injected via @EnvironmentObject
- **Separation of Concerns**: Views handle presentation, ViewModels manage state and business logic, Services provide reusable functionality
- **Reactive Data Flow**: Using Combine publishers and @Published properties for state updates

**Architecture Layers:**
1. **Views**: SwiftUI views that observe ViewModels and Services
2. **ViewModels**: ObservableObject classes containing screen-specific business logic
3. **Services**: Singleton instances for cross-cutting concerns (authentication, device activity, storage)
4. **Models**: Data structures and domain objects

**Example Implementation:**
```swift
// ViewModel with business logic
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var authState: AuthState = .unauthenticated
    
    private let subscriptionManager: SubscriptionManager
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }
    
    func signInWithGoogle() async throws {
        // Business logic implementation
    }
}

// View using ViewModel and Services
struct LoginScreen: View {
    @StateObject private var viewModel = AuthenticationViewModel(
        subscriptionManager: SubscriptionManager.shared
    )
    @EnvironmentObject private var deviceActivityService: DeviceActivityService
    
    var body: some View {
        // UI implementation
    }
}
```

**Pattern Guidelines:**
- Create ViewModels for screens with complex state management
- Use @StateObject for ViewModel ownership in views
- Inject services into ViewModels via constructor dependency injection
- Keep services as @EnvironmentObject for global access
- Use async/await for asynchronous operations in ViewModels

### Inter-Process Communication Architecture
```
Main App ←→ App Groups (UserDefaults) ←→ Extensions
    ↓              ↓                          ↓
  GRDB        Darwin Notifications      Shield UI
    ↓              ↓                          ↓
Firestore    Real-time Events          User Feedback
```

### Key Architectural Components

#### 1. **App Extensions Communication**
- **DeviceActivityMonitorExtension**: Background monitoring of app usage
  - Triggers via `DeviceActivitySchedule`
  - Communicates through Darwin notifications
  - Stores data in shared App Group container
  
- **Shield Extension**: Custom UI when blocked apps accessed
  - Uses `SharedData` for configuration
  - Reads blocking state from shared UserDefaults
  
- **DeviceReportExtension**: Usage statistics and visualizations
  - Accesses shared GRDB database
  - Generates reports from activity data

#### 2. **Data Flow and Storage**
- **SharedData** (`SharedData.swift`): Type-safe wrapper for App Group UserDefaults
- **Storage** (`Storage.swift`): Unified interface for dual storage system
  - GRDB for local SQLite storage (offline-first)
  - Firestore for cloud backup and sync
- **App Blocking Sessions**: Tracked with start/end times, daily statistics

#### 3. **Cross-Extension Communication**
- **Darwin Notifications** (`DarwinNotificationManager`): Low-level IPC
  ```swift
  // Example notifications:
  - "appBlockingStarted"
  - "appBlockingEnded"
  - "refreshBlockingStats"
  ```
- **App Groups**: Shared container `group.com.app.antisocial.sharedData`
- **SharedDataConstants**: Centralized keys for shared data access

#### 4. **Authentication and User Management**
- **Multi-provider**: Google Sign-In, Apple Sign-In, Anonymous
- **AuthenticationViewModel**: Central auth state management
- **Firebase Auth**: Backend integration
- **Persistent state**: Via `@AppStorage` and Keychain

#### 5. **Screen Time Integration**
- **FamilyControlsManager**: Handles Screen Time permissions
- **DeviceActivityService**: Configures app restrictions
- **BlockingNotificationService**: Manages blocking sessions
- **ManagedSettingsStore**: Named store for app restrictions

### Critical Implementation Details

#### App Group Configuration
- Identifier: `group.com.app.antisocial.sharedData`
- Must be enabled in all targets (main app + extensions)
- Used for UserDefaults and GRDB database sharing

#### Extension Entry Points
- **DeviceActivityMonitorExtension**: `intervalDidStart`, `intervalDidEnd`, `eventDidReachThreshold`
- **Shield**: `ShieldConfigurationDataSource` methods
- **DeviceReport**: `DeviceActivityReportScene` configuration

#### Notification Handling
- Local notifications require user permission
- Darwin notifications work without permission (system-level)
- Extension → App communication via Darwin notifications
- App → Extension communication via shared UserDefaults

#### GRDB Database Location
```swift
let dbPath = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.app.antisocial.sharedData")!
    .appendingPathComponent("db.sqlite")
```

### Development Workflow

#### When Adding New Features
1. Consider if feature needs extension access
2. Use `SharedDataConstants` for new shared keys
3. Update both GRDB and Firestore schemas if needed
4. Test inter-process communication thoroughly

#### Common Issues and Solutions
- **Extensions not seeing data**: Check App Group configuration
- **Darwin notifications not firing**: Ensure proper registration
- **GRDB access errors**: Verify database path and permissions
- **Build errors after clean**: Run `xcodebuild -resolvePackageDependencies`

#### Testing Extensions
- Extensions run in separate processes
- Use Console.app to view extension logs
- Test on real device for accurate Screen Time behavior
- Simulator limitations: Some Family Controls features unavailable

### Important Files for Architecture Understanding
- `AntiSocial/App/AntiSocialApp.swift`: Main app entry and initialization
- `AntiSocial/Utilities/Services/DeviceActivity/SharedData.swift`: Cross-process data sharing
- `AntiSocial/Utilities/Services/Storage/Storage.swift`: Dual storage implementation
- `AntiSocial/Utilities/Managers/DarwinNotificationManager.swift`: IPC mechanism
- `AntiSocial/Utilities/Constants/SharedDataConstants.swift`: Shared data keys
- `DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift`: Background monitoring
- `Shield/ShieldConfigurationExtension.swift`: App blocking UI

## Development Tools and Configuration

### Required VS Code Extensions for iOS Development
Based on your project configuration, these extensions are recommended:
- **Swift Language Support**: `sswg.swift-lang` or `swiftlang.swift-vscode`
- **SweetPad**: `sweetpad.sweetpad` - iOS/Swift development with Xcode integration
- **CodeLLDB**: `vadimcn.vscode-lldb` - Debugging support
- **LLDB DAP**: `llvm-vs-code-extensions.lldb-dap` - LLDB debugger integration

### Debugging Configuration
```json
{
    "lldb.library": "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB",
    "lldb.launch.expressions": "native"
}
```

### Additional Tools
- **REST Client**: For testing API endpoints
- **Claude Code**: AI assistance integrated in VS Code
- **Cline**: Additional AI development assistance

## Essential Documentation References

### Apple Developer Documentation
- **Screen Time & Family Controls**: https://developer.apple.com/documentation/familycontrols
- **DeviceActivity Framework**: https://developer.apple.com/documentation/deviceactivity
- **ManagedSettings**: https://developer.apple.com/documentation/managedsettings
- **App Extensions**: https://developer.apple.com/documentation/foundation/app_extension_support
- **SwiftUI**: https://developer.apple.com/documentation/swiftui
- **Combine Framework**: https://developer.apple.com/documentation/combine

### Firebase Documentation
- **Firebase Auth iOS**: https://firebase.google.com/docs/auth/ios/start
- **Cloud Firestore iOS**: https://firebase.google.com/docs/firestore/quickstart#ios
- **Google Sign-In**: https://developers.google.com/identity/sign-in/ios/start
- **Firebase Analytics**: https://firebase.google.com/docs/analytics/get-started?platform=ios

### Third-Party Libraries
- **GRDB (SQLite)**: https://github.com/groue/GRDB.swift
- **RevenueCat**: https://docs.revenuecat.com/docs/ios
- **Codemagic CI/CD**: https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/

### Swift & iOS Development
- **Swift Language Guide**: https://docs.swift.org/swift-book/documentation/the-swift-programming-language
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/

### Testing & Debugging
- **XCTest Framework**: https://developer.apple.com/documentation/xctest
- **Instruments**: https://help.apple.com/instruments/mac/current/
- **TestFlight**: https://developer.apple.com/testflight/