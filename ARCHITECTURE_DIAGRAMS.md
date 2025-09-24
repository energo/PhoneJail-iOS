# Архитектура приложения AntiSocial iOS

## 1. Система аутентификации

```mermaid
graph TB
    A[LoginView] --> B[AuthenticationViewModel]
    B --> C[Firebase Auth]
    B --> D[SubscriptionManager]
    B --> E[Storage]
    
    C --> F[Email/Password Auth]
    C --> G[Google Sign-In]
    C --> H[Apple Sign-In]
    C --> I[Anonymous Auth]
    
    B --> J[ASUser Model]
    J --> E
    
    E --> K[GRDBStorage - Local]
    E --> L[FirestoreStorage - Cloud]
    
    B --> M[AuthenticationState]
    M --> N[.unauthenticated]
    M --> O[.authenticating]
    M --> P[.authenticated]
    
    P --> Q[MainView]
    Q --> R[OnboardingScreen]
    Q --> S[AppMonitorScreen]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style E fill:#e8f5e8
```

## 2. Система блокировки приложений

```mermaid
graph TB
    A[AppBlockingSectionView] --> B[AppBlockingViewModel]
    B --> C[DeviceActivityScheduleService]
    C --> D[DeviceActivityCenter]
    
    D --> E[DeviceActivityMonitorExtension]
    E --> F[ManagedSettingsStore]
    F --> G[App Restrictions]
    
    B --> H[AppBlockingLogger]
    H --> I[BlockingSession]
    H --> J[DailyStats]
    
    I --> K[BlockingType]
    K --> L[appBlocking]
    K --> M[appInterruption]
    K --> N[scheduleBlocking]
    K --> O[pomodoro]
    
    H --> P[SharedData]
    P --> Q[UserDefaults Group]
    
    E --> R[BlockingNotificationService]
    R --> S[Local Notifications]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style E fill:#fff3e0
    style H fill:#e8f5e8
```

## 3. Система Pomodoro

```mermaid
graph TB
    A[PomodoroSectionView] --> B[PomodoroViewModel]
    B --> C[PomodoroBlockService]
    C --> D[DeviceActivityScheduleService]
    
    B --> E[PomodoroSession]
    E --> F[Phase: focus/break]
    E --> G[Timer Management]
    
    C --> H[DeviceActivityCenter]
    H --> I[DeviceActivityMonitorExtension]
    I --> J[ManagedSettingsStore]
    
    B --> K[SessionType]
    K --> L[focus]
    K --> M[breakTime]
    
    B --> N[PomodoroViewState]
    N --> O[inactive]
    N --> P[activeFocus]
    N --> Q[activeBreak]
    N --> R[focusCompletion]
    N --> S[allSessionsCompleted]
    
    B --> T[Statistics]
    T --> U[lifetimeFocusTime]
    T --> V[weeklyFocusTime]
    T --> W[todayFocusTime]
    
    B --> X[Settings]
    X --> Y[focusDuration]
    X --> Z[breakDuration]
    X --> AA[autoStartBreak]
    X --> BB[notificationsEnabled]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style E fill:#e8f5e8
```

## 4. Система расписания блокировок

```mermaid
graph TB
    A[BlockSchedulerSectionView] --> B[BlockSchedulerViewModel]
    B --> C[BlockSchedulerService]
    
    C --> D[BlockSchedule Model]
    D --> E[scheduleId]
    D --> F[timeInterval]
    D --> G[selectedApps]
    D --> H[isActive]
    
    C --> I[DeviceActivityCenter]
    I --> J[DeviceActivityMonitorExtension]
    J --> K[ManagedSettingsStore]
    
    B --> L[Schedule Management]
    L --> M[activateSchedule]
    L --> N[deactivateSchedule]
    L --> O[updateSchedule]
    L --> P[deleteSchedule]
    
    C --> Q[Notification System]
    Q --> R[Schedule Start Notification]
    Q --> S[Schedule End Notification]
    
    J --> T[handleScheduleStart]
    T --> U[Apply App Restrictions]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style D fill:#e8f5e8
```

## 5. Система хранения данных

```mermaid
graph TB
    A[Storage] --> B[GRDBStorage - Local]
    A --> C[FirestoreStorage - Cloud]
    
    B --> D[SQLite Database]
    D --> E[User Data]
    D --> F[Settings]
    D --> G[Statistics]
    
    C --> H[Firebase Firestore]
    H --> I[User Documents]
    H --> J[Settings Collection]
    H --> K[Statistics Collection]
    
    A --> L[SyncState]
    L --> M[idle]
    L --> N[syncing]
    L --> O[completed]
    L --> P[failed]
    
    A --> Q[SyncMode]
    Q --> R[smart]
    Q --> S[force]
    
    T[AuthenticationViewModel] --> A
    U[AppBlockingLogger] --> A
    V[PomodoroViewModel] --> A
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style D fill:#e8f5e8
```

## 6. Основной поток приложения

```mermaid
graph TB
    A[AntiSocialApp] --> B[MainView]
    
    B --> C{AuthenticationState}
    C -->|unauthenticated| D[LoginView]
    C -->|authenticated| E{isFirstRun}
    
    E -->|true| F[OnboardingScreen]
    E -->|false| G[AppMonitorScreen]
    
    F --> H[MainGoalQuizView]
    F --> I[HowWorksView]
    F --> J[ConnectScreenTimeView]
    F --> K[TurnOnNotificationsView]
    
    G --> L[AppBlockingSectionView]
    G --> M[BlockSchedulerSectionView]
    G --> N[PomodoroSectionView]
    G --> O[ScreenTimeTodayView]
    G --> P[ActivityReportView]
    
    G --> Q[ProfileScreen]
    G --> R[NotificationsScreen]
    
    S[DeviceActivityMonitorExtension] --> T[App Restrictions]
    S --> U[Notifications]
    
    V[DeviceReportExtension] --> W[Screen Time Reports]
    V --> X[Activity Reports]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style G fill:#fff3e0
    style S fill:#e8f5e8
```

## 7. Система уведомлений

```mermaid
graph TB
    A[LocalNotificationManager] --> B[UNUserNotificationCenter]
    
    A --> C[Notification Types]
    C --> D[Pomodoro Notifications]
    C --> E[Schedule Notifications]
    C --> F[Blocking Notifications]
    C --> G[Statistics Notifications]
    
    D --> H[Focus Start]
    D --> I[Focus End]
    D --> J[Break Start]
    D --> K[Break End]
    D --> L[All Sessions Complete]
    
    E --> M[Schedule Start]
    E --> N[Schedule End]
    
    F --> O[App Blocked]
    F --> P[App Unblocked]
    
    G --> Q[Daily Summary]
    G --> R[Weekly Report]
    
    S[ScheduleNotificationHandler] --> T[UNUserNotificationCenterDelegate]
    T --> U[Handle Notifications]
    
    V[DeviceActivityMonitorExtension] --> W[Extension Notifications]
    W --> X[Blocking Status]
    W --> Y[Schedule Events]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style S fill:#fff3e0
    style V fill:#e8f5e8
```

## 8. Система статистики и отчетов

```mermaid
graph TB
    A[AppBlockingLogger] --> B[BlockingSession]
    A --> C[DailyStats]
    
    B --> D[Session Tracking]
    D --> E[Start Time]
    D --> F[End Time]
    D --> G[Duration]
    D --> H[Blocked Apps]
    
    C --> I[Daily Metrics]
    I --> J[Total Focus Time]
    I --> K[Session Count]
    I --> L[App Usage]
    
    A --> M[SharedData]
    M --> N[UserDefaults Group]
    N --> O[Cross-Extension Data]
    
    P[ScreenTimeTodayView] --> Q[DeviceActivityReport]
    Q --> R[Screen Time Data]
    
    S[ActivityReportView] --> T[DeviceActivityReport]
    T --> U[Activity Data]
    
    V[DeviceReportExtension] --> W[ActivityReport]
    W --> X[App Usage Stats]
    W --> Y[Pickup Count]
    W --> Z[Top Apps]
    
    style A fill:#e1f5fe
    style P fill:#f3e5f5
    style S fill:#fff3e0
    style V fill:#e8f5e8
```

## 9. Система подписок и монетизации

```mermaid
graph TB
    A[SubscriptionManager] --> B[RevenueCat]
    B --> C[Purchase Validation]
    B --> D[Subscription Status]
    
    A --> E[Entitlements]
    E --> F[Premium Features]
    E --> G[Unlimited Sessions]
    E --> H[Advanced Statistics]
    
    I[AuthenticationViewModel] --> A
    J[AppMonitorScreen] --> K[Paywall]
    K --> A
    
    A --> L[Subscription States]
    L --> M[active]
    L --> N[expired]
    L --> O[cancelled]
    L --> P[never_purchased]
    
    A --> Q[Purchase Flow]
    Q --> R[Show Paywall]
    Q --> S[Process Purchase]
    Q --> T[Validate Receipt]
    Q --> U[Update Entitlements]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style K fill:#fff3e0
```

## 10. Архитектура расширений

```mermaid
graph TB
    A[Main App] --> B[DeviceActivityMonitorExtension]
    A --> C[DeviceReportExtension]
    A --> D[Shield Configuration Extension]
    
    B --> E[Device Activity Monitoring]
    E --> F[Interval Start/End]
    E --> G[App Blocking]
    E --> H[Schedule Management]
    
    C --> I[Activity Reports]
    I --> J[Screen Time Data]
    I --> K[App Usage Stats]
    I --> L[Device Activity Reports]
    
    D --> M[Shield Configuration]
    M --> N[App Blocking UI]
    M --> O[Custom Block Screens]
    
    P[SharedData] --> Q[UserDefaults Group]
    Q --> A
    Q --> B
    Q --> C
    Q --> D
    
    R[ManagedSettings] --> S[App Restrictions]
    R --> T[Website Restrictions]
    R --> U[Content Restrictions]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style D fill:#e8f5e8
```

## 11. Система FamilyControls и ManagedSettings

```mermaid
graph TB
    A[FamilyControlsManager] --> B[AuthorizationCenter]
    B --> C[Screen Time Permissions]
    C --> D[.approved]
    C --> E[.denied]
    C --> F[.notDetermined]
    
    G[ShieldService] --> H[ManagedSettingsStore]
    H --> I[App Restrictions]
    H --> J[Website Restrictions]
    H --> K[Content Restrictions]
    
    L[SelectAppsModel] --> M[FamilyActivitySelection]
    M --> N[Application Tokens]
    M --> O[Category Tokens]
    M --> P[Web Domain Tokens]
    
    Q[AppInterruptionViewModel] --> R[DeviceActivityCenter]
    R --> S[Device Activity Monitoring]
    S --> T[App Usage Tracking]
    S --> U[Threshold Events]
    
    V[DeviceActivityScheduleService] --> W[DeviceActivitySchedule]
    W --> X[Scheduled Intervals]
    W --> Y[Event Triggers]
    
    Z[DeviceActivityMonitorExtension] --> AA[ManagedSettingsStore]
    AA --> BB[Apply Restrictions]
    AA --> CC[Remove Restrictions]
    
    style A fill:#e1f5fe
    style G fill:#f3e5f5
    style L fill:#fff3e0
    style Z fill:#e8f5e8
```

## 12. Система SharedData и межпроцессного взаимодействия

```mermaid
graph TB
    A[SharedData] --> B[App Group Container]
    B --> C[group.com.app.antisocial.sharedData]
    
    C --> D[UserDefaults Suite]
    D --> E[App Blocking Data]
    D --> F[Pomodoro Settings]
    D --> G[Screen Time Data]
    D --> H[Statistics]
    
    I[Main App] --> A
    J[DeviceActivityMonitorExtension] --> A
    K[DeviceReportExtension] --> A
    L[Shield Extension] --> A
    
    M[Darwin Notifications] --> N[Inter-Process Communication]
    N --> O[appBlockingStarted]
    N --> P[appBlockingEnded]
    N --> Q[refreshBlockingStats]
    N --> R[pomodoroPhaseChanged]
    
    S[GRDB Database] --> T[Shared SQLite]
    T --> U[User Data]
    T --> V[Session History]
    T --> W[Statistics]
    
    X[FirestoreStorage] --> Y[Cloud Sync]
    Y --> Z[User Documents]
    Y --> AA[Settings Collection]
    Y --> BB[Statistics Collection]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style M fill:#fff3e0
    style S fill:#e8f5e8
```

## 13. Детальная архитектура DeviceActivityMonitorExtension

```mermaid
graph TB
    A[DeviceActivityMonitorExtension] --> B[DeviceActivityMonitor]
    
    B --> C[intervalDidStart]
    C --> D{Schedule Type}
    D -->|schedule_| E[handleScheduleStart]
    D -->|scheduledBlock_| F[handleScheduledBlock]
    D -->|pomodoro| G[handleStartPomodoroPhases]
    
    E --> H[Load Schedule Config]
    H --> I[Apply App Restrictions]
    
    F --> J[Load Block Config]
    J --> K[Apply Blocking Rules]
    
    G --> L[Check Phase Type]
    L --> M[Focus Phase]
    L --> N[Break Phase]
    
    M --> O[Apply All App Restrictions]
    N --> P[Remove Restrictions]
    
    B --> Q[intervalDidEnd]
    Q --> R[Remove Restrictions]
    Q --> S[Log Session Data]
    
    B --> T[eventDidReachThreshold]
    T --> U[App Usage Limit Reached]
    U --> V[Trigger Interruption]
    
    W[SharedData] --> X[Configuration Data]
    X --> Y[App Selections]
    X --> Z[Schedule Settings]
    X --> AA[Pomodoro Settings]
    
    BB[ManagedSettingsStore] --> CC[Apply Restrictions]
    CC --> DD[Block Apps]
    CC --> EE[Block Websites]
    CC --> FF[Block Content]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style W fill:#fff3e0
    style BB fill:#e8f5e8
```

## 14. Система Shield Configuration Extension

```mermaid
graph TB
    A[ShieldConfigurationExtension] --> B[ShieldConfigurationDataSource]
    
    B --> C[configuration]
    C --> D[Shield Configuration]
    D --> E[Custom UI Elements]
    D --> F[Blocking Messages]
    D --> G[Action Buttons]
    
    H[ShieldService] --> I[ManagedSettingsStore]
    I --> J[Current Restrictions]
    J --> K[Blocked Apps]
    J --> L[Blocked Websites]
    J --> M[Blocked Content]
    
    N[SharedData] --> O[Shield Configuration]
    O --> P[Custom Messages]
    O --> Q[Button Actions]
    O --> R[Unlock Information]
    
    S[User Interaction] --> T[Shield Actions]
    T --> U[Request Unlock]
    T --> V[View Statistics]
    T --> W[Contact Support]
    
    X[Unlock Request] --> Y[Notification to Main App]
    Y --> Z[Handle Unlock Logic]
    
    style A fill:#e1f5fe
    style H fill:#f3e5f5
    style N fill:#fff3e0
    style S fill:#e8f5e8
```

## 15. Система DeviceReportExtension

```mermaid
graph TB
    A[DeviceReportExtension] --> B[DeviceActivityReportScene]
    
    B --> C[ScreenTimeTodayView]
    C --> D[DeviceActivityReport]
    D --> E[Today's Screen Time]
    D --> F[App Usage Stats]
    
    B --> G[ActivityReportView]
    G --> H[DeviceActivityReport]
    H --> I[Historical Data]
    H --> J[Date Selection]
    
    K[ScreenTimeSectionView] --> L[ActivityReport Data]
    L --> M[Total Duration]
    L --> N[Top Apps]
    L --> O[Pickup Count]
    
    P[StatsActivityReport] --> Q[Statistics Processing]
    Q --> R[Focus Time Calculation]
    Q --> S[Distraction Analysis]
    Q --> T[Progress Tracking]
    
    U[SharedData] --> V[Report Configuration]
    V --> W[Date Filters]
    V --> X[Data Sources]
    V --> Y[Display Settings]
    
    Z[DeviceActivityReport.Context] --> AA[Report Contexts]
    AA --> BB[totalActivity]
    AA --> CC[statsActivity]
    AA --> DD[totalActivityImproved]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style K fill:#fff3e0
    style U fill:#e8f5e8
```
