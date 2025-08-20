//
//  AdaptiveUI+Extension.swift
//  DeviceReportExtension
//
//  Duplicate of AdaptiveUI for extensions (can't import from main app)
//

import SwiftUI

// MARK: - Adaptive Device Category
enum AdaptiveDeviceCategory {
    case compact      // iPhone SE (375 width)
    case standard     // iPhone 12-15 standard (390-393 width)  
    case pro          // iPhone Pro models (402 width)
    case plus         // iPhone Plus models (430 width)
    case proMax       // iPhone Pro Max models (440 width)
    
    static var current: AdaptiveDeviceCategory {
        let width = UIScreen.main.bounds.width
        
        switch width {
        case ..<380:
            return .compact
        case 380..<400:
            return .standard
        case 400..<410:
            return .pro
        case 410..<435:
            return .plus
        default:
            return .proMax
        }
    }
    
    var isCompact: Bool {
        self == .compact
    }
    
    var isLarge: Bool {
        self == .proMax || self == .plus
    }
}

// MARK: - Adaptive Values
struct AdaptiveValues {
    // Typography
    struct Typography {
        var largeTitle: CGFloat
        var title1: CGFloat
        var title2: CGFloat
        var title3: CGFloat
        var headline: CGFloat
        var body: CGFloat
        var callout: CGFloat
        var subheadline: CGFloat
        var footnote: CGFloat
        var caption1: CGFloat
        var caption2: CGFloat
        
        // Custom sizes
        var screenTimeDisplay: CGFloat
        var statsValue: CGFloat
        var statsLabel: CGFloat
    }
    
    // Spacing
    struct Spacing {
        var xxSmall: CGFloat
        var xSmall: CGFloat
        var small: CGFloat
        var medium: CGFloat
        var large: CGFloat
        var xLarge: CGFloat
        var xxLarge: CGFloat
    }
    
    // Component Sizes
    struct ComponentSizes {
        var iconSmall: CGFloat
        var iconMedium: CGFloat
        var iconLarge: CGFloat
        var buttonHeight: CGFloat
        var appIconSize: CGFloat
        var cardCornerRadius: CGFloat
    }
    
    let typography: Typography
    let spacing: Spacing
    let componentSizes: ComponentSizes
    
    static var current: AdaptiveValues {
        switch AdaptiveDeviceCategory.current {
        case .compact:
            return AdaptiveValues(
                typography: Typography(
                    largeTitle: 32,
                    title1: 26,
                    title2: 20,
                    title3: 18,
                    headline: 16,
                    body: 15,
                    callout: 14,
                    subheadline: 13,
                    footnote: 12,
                    caption1: 11,
                    caption2: 10,
                    screenTimeDisplay: 100,
                    statsValue: 20,
                    statsLabel: 10
                ),
                spacing: Spacing(
                    xxSmall: 2,
                    xSmall: 4,
                    small: 8,
                    medium: 12,
                    large: 16,
                    xLarge: 20,
                    xxLarge: 24
                ),
                componentSizes: ComponentSizes(
                    iconSmall: 16,
                    iconMedium: 20,
                    iconLarge: 24,
                    buttonHeight: 40,
                    appIconSize: 26,
                    cardCornerRadius: 8
                )
            )
            
        case .standard:
            return AdaptiveValues(
                typography: Typography(
                    largeTitle: 34,
                    title1: 28,
                    title2: 22,
                    title3: 20,
                    headline: 17,
                    body: 17,
                    callout: 16,
                    subheadline: 15,
                    footnote: 13,
                    caption1: 12,
                    caption2: 11,
                    screenTimeDisplay: 120,
                    statsValue: 24,
                    statsLabel: 11
                ),
                spacing: Spacing(
                    xxSmall: 4,
                    xSmall: 6,
                    small: 10,
                    medium: 16,
                    large: 20,
                    xLarge: 28,
                    xxLarge: 32
                ),
                componentSizes: ComponentSizes(
                    iconSmall: 18,
                    iconMedium: 24,
                    iconLarge: 28,
                    buttonHeight: 44,
                    appIconSize: 30,
                    cardCornerRadius: 10
                )
            )
            
        case .pro:
            return AdaptiveValues(
                typography: Typography(
                    largeTitle: 34,
                    title1: 28,
                    title2: 22,
                    title3: 20,
                    headline: 17,
                    body: 17,
                    callout: 16,
                    subheadline: 15,
                    footnote: 13,
                    caption1: 12,
                    caption2: 11,
                    screenTimeDisplay: 125,
                    statsValue: 24,
                    statsLabel: 11
                ),
                spacing: Spacing(
                    xxSmall: 4,
                    xSmall: 6,
                    small: 10,
                    medium: 16,
                    large: 20,
                    xLarge: 28,
                    xxLarge: 32
                ),
                componentSizes: ComponentSizes(
                    iconSmall: 18,
                    iconMedium: 24,
                    iconLarge: 28,
                    buttonHeight: 44,
                    appIconSize: 30,
                    cardCornerRadius: 10
                )
            )
            
        case .plus:
            return AdaptiveValues(
                typography: Typography(
                    largeTitle: 36,
                    title1: 30,
                    title2: 24,
                    title3: 22,
                    headline: 18,
                    body: 18,
                    callout: 17,
                    subheadline: 16,
                    footnote: 14,
                    caption1: 12,
                    caption2: 11,
                    screenTimeDisplay: 130,
                    statsValue: 26,
                    statsLabel: 12
                ),
                spacing: Spacing(
                    xxSmall: 4,
                    xSmall: 8,
                    small: 12,
                    medium: 20,
                    large: 24,
                    xLarge: 32,
                    xxLarge: 40
                ),
                componentSizes: ComponentSizes(
                    iconSmall: 20,
                    iconMedium: 26,
                    iconLarge: 32,
                    buttonHeight: 48,
                    appIconSize: 34,
                    cardCornerRadius: 12
                )
            )
            
        case .proMax:
            return AdaptiveValues(
                typography: Typography(
                    largeTitle: 38,
                    title1: 32,
                    title2: 26,
                    title3: 24,
                    headline: 19,
                    body: 19,
                    callout: 18,
                    subheadline: 17,
                    footnote: 15,
                    caption1: 13,
                    caption2: 12,
                    screenTimeDisplay: 140,
                    statsValue: 28,
                    statsLabel: 12
                ),
                spacing: Spacing(
                    xxSmall: 4,
                    xSmall: 8,
                    small: 12,
                    medium: 20,
                    large: 24,
                    xLarge: 32,
                    xxLarge: 40
                ),
                componentSizes: ComponentSizes(
                    iconSmall: 20,
                    iconMedium: 26,
                    iconLarge: 32,
                    buttonHeight: 48,
                    appIconSize: 34,
                    cardCornerRadius: 12
                )
            )
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Apply adaptive font size based on current device
    func adaptiveFont(_ keyPath: KeyPath<AdaptiveValues.Typography, CGFloat>) -> some View {
        self.font(.system(size: AdaptiveValues.current.typography[keyPath: keyPath]))
    }
    
    /// Apply adaptive padding based on current device
    func adaptivePadding(_ keyPath: KeyPath<AdaptiveValues.Spacing, CGFloat>) -> some View {
        self.padding(AdaptiveValues.current.spacing[keyPath: keyPath])
    }
    
    /// Apply adaptive frame based on current device
    func adaptiveFrame(
        width: KeyPath<AdaptiveValues.ComponentSizes, CGFloat>? = nil,
        height: KeyPath<AdaptiveValues.ComponentSizes, CGFloat>? = nil
    ) -> some View {
        self.frame(
            width: width.map { AdaptiveValues.current.componentSizes[keyPath: $0] },
            height: height.map { AdaptiveValues.current.componentSizes[keyPath: $0] }
        )
    }
    
    /// Apply adaptive corner radius
    func adaptiveCornerRadius() -> some View {
        self.cornerRadius(AdaptiveValues.current.componentSizes.cardCornerRadius)
    }
}

// MARK: - Convenience Properties
extension AdaptiveValues {
    static var deviceCategory: AdaptiveDeviceCategory {
        AdaptiveDeviceCategory.current
    }
    
    static var isCompactDevice: Bool {
        deviceCategory.isCompact
    }
    
    static var isLargeDevice: Bool {
        deviceCategory.isLarge
    }
}