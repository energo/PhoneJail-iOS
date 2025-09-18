//
//  TextScreen.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//


import SwiftUI

struct TextScreen: View {
  @Environment(\.dismiss) var dismiss
  private let adaptive = AdaptiveValues.current
  
  let text: String
  let title: String
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      VStack(spacing: 16) {
        headerView
          .padding(.horizontal, 32)
          .padding(.top, 16)
        
        separatorView
          .padding(.horizontal, 32)
        
        textView
          .blurBackground()
          .padding(.horizontal, 32)
          .padding(.vertical, adaptive.spacing.small)
        
        Spacer()
        
        backButton
        
        Spacer()
      }
      .padding(.top, 8)
    }
  }
  
  private var backButton: some View {
    ButtonBack {
      dismiss()
    }
  }
  
  private var separatorView: some View {
    SeparatorView()
  }
  
  private var headerView: some View {
    HStack {
      HStack(spacing: 8) {
        Text(title)
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(Color.white)
      }
      
      Spacer()
      
      Button(action: {
        self.dismiss()
      }) {
        Image(.icNavClose)
          .frame(width: 24, height: 24)
      }
    }
  }
  
  
  private var textView: some View {
    VStack {
      ScrollView {
        Text(text)
          .multilineTextAlignment(.leading)
          .foregroundColor(Color.white)
      }
      .padding(16)
    }
  }
  
  private var okButton: some View {
    GradientButton(title: "Ok") {
      dismiss()
    }
  }
}

//MARK: - Previews
#Preview {
  TextScreen(text: TextScreen.terms, title: "Terms")
}

//MARK: - Extensions 
extension TextScreen {
  static let terms =
 """
Terms and Conditions

These terms and conditions apply to the Phone Jail app (hereby referred to as "Application") for mobile devices that was created by Yuriy Chernin (hereby referred to as "Service Provider") as a Freemium service.

About Phone Jail

Phone Jail is an intelligent app blocker and screen time companion designed to help you:

Block distracting apps and categories with optional Strict Mode
Set custom blocking durations from 10 minutes to 3 hours
Track your focus time with detailed analytics - Focused, Distracted, and Offline breakdowns
Monitor app usage patterns and trends
Boost productivity and digital wellness
Upon downloading or utilizing the Application, you are automatically agreeing to the following terms. It is strongly advised that you thoroughly read and understand these terms prior to using the Application. Unauthorized copying, modification of the Application, any part of the Application, or our trademarks is strictly prohibited. Any attempts to extract the source code of the Application, translate the Application into other languages, or create derivative versions are not permitted. All trademarks, copyrights, database rights, and other intellectual property rights related to the Application remain the property of the Service Provider.

Use of the Service

Account Registration

Some features may require you to create an account. You are responsible for:

Providing accurate and complete information
Maintaining the security of your account credentials
All activities that occur under your account
The Service Provider is dedicated to ensuring that the Application is as beneficial and efficient as possible. As such, they reserve the right to modify the Application or charge for their services at any time and for any reason. The Service Provider assures you that any charges for the Application or its services will be clearly communicated to you.

App Features and Functionality

App Blocking

Phone Jail provides app blocking functionality to help you focus. When you enable blocking:

Selected apps will be temporarily restricted
Strict Mode prevents interruptions even if the Application is closed
You can set custom durations for blocking sessions
Use "Swipe to Block" for fast blocking sessions on demand
Analytics and Insights

The Application provides usage analytics including:

Focus time tracking with hourly breakdowns
Detailed usage per app - Instagram, Snapchat, Facebook and more
Daily focus reports and trends
Smart alerts when screentime limits are reached
Important Notice

Phone Jail requires certain system permissions to function properly. By using the Application, you grant necessary permissions for app monitoring and blocking features to work effectively.

The Application stores and processes personal data that you have provided to the Service Provider in order to provide the Service. It is your responsibility to maintain the security of your phone and access to the Application. The Service Provider strongly advises against jailbreaking or rooting your phone, which involves removing software restrictions and limitations imposed by the official operating system of your device. Such actions could expose your phone to malware, viruses, malicious programs, compromise your phone's security features, and may result in the Application not functioning correctly or at all.

iOS-Specific Terms

Screen Time Integration

Phone Jail integrates with iOS Screen Time features to provide app blocking functionality. By using the Application, you acknowledge and agree that:

The app requires Screen Time permissions to function properly
You must grant necessary permissions when prompted
The app's functionality depends on iOS Screen Time API availability
Apple may change Screen Time features which could affect app functionality
iOS App Store Compliance

This Application is distributed through the Apple App Store and complies with all App Store guidelines. You acknowledge that:

Apple is not responsible for the Application or its content
Your use of the app is subject to Apple's Terms of Use
Any claims regarding the app should be directed to us, not Apple
Subscription and Payments

Free and Premium Features

Phone Jail offers both free and premium features. Premium features may require a subscription.

Billing

Subscriptions are billed through the Apple App Store
Payment will be charged upon confirmation of purchase
Subscriptions automatically renew unless cancelled
You can manage subscriptions in your App Store account settings
Please note that the Application utilizes third-party services that have their own Terms and Conditions. Below are the links to the Terms and Conditions of the third-party service providers used by the Application:

Google Play Services
Google Analytics for Firebase
Firebase Crashlytics
RevenueCat
Please be aware that the Service Provider does not assume responsibility for certain aspects. Some functions of the Application require an active internet connection, which can be Wi-Fi or provided by your mobile network provider. The Service Provider cannot be held responsible if the Application does not function at full capacity due to lack of access to Wi-Fi or if you have exhausted your data allowance.

If you are using the application outside of a Wi-Fi area, please be aware that your mobile network provider's agreement terms still apply. Consequently, you may incur charges from your mobile provider for data usage during the connection to the application, or other third-party charges. By using the application, you accept responsibility for any such charges, including roaming data charges if you use the application outside of your home territory (i.e., region or country) without disabling data roaming. If you are not the bill payer for the device on which you are using the application, they assume that you have obtained permission from the bill payer.

Similarly, the Service Provider cannot always assume responsibility for your usage of the application. For instance, it is your responsibility to ensure that your device remains charged. If your device runs out of battery and you are unable to access the Service, the Service Provider cannot be held responsible.

In terms of the Service Provider's responsibility for your use of the application, it is important to note that while they strive to ensure that it is updated and accurate at all times, they do rely on third parties to provide information to them so that they can make it available to you. The Service Provider accepts no liability for any loss, direct or indirect, that you experience as a result of relying entirely on this functionality of the application.

The Service Provider may wish to update the application at some point. The application is currently available for iOS devices and the requirements may change. You will need to download the updates if you want to continue using the application. The Service Provider does not guarantee that it will always update the application so that it is compatible with your iOS version. However, you agree to always accept updates to the application when offered to you.

The Service Provider may also wish to cease providing the application and may terminate its use at any time without providing termination notice to you. Unless they inform you otherwise, upon any termination:

The rights and licenses granted to you in these terms will end
You must cease using the application
You must delete the application from your device
Changes to These Terms and Conditions

The Service Provider may periodically update their Terms and Conditions. Therefore, you are advised to review this page regularly for any changes. The Service Provider will notify you of any changes by posting the new Terms and Conditions on this page.

Effective as of: August 08, 2025

Contact Us

If you have any questions or suggestions about the Terms and Conditions, please contact us via email: smartclickdeveloper@gmail.com


"""
  
  static let privacy =
  """
Privacy Policy

This privacy policy applies to the Phone Jail app (hereby referred to as "Application") for mobile devices created by Yuriy Chernin ("Service Provider") as a Freemium service. This service is intended for use "AS IS".

Our Privacy Commitments

Your data stays on your device - Focus analytics and usage data are processed locally
Minimal data collection - We only collect what's necessary to provide our service
We never sell your data - Your information is never sold to third parties
Privacy by design - Privacy is built into every feature we develop
Information Collection and Use

Information You Provide

Account Information: Email address and name (if you create an account)
Support Information: Any information you provide when contacting us for support
Preferences: Your app blocking preferences and settings
Information Collected Automatically

The Application collects information such as:

Your device's IP address
Pages visited, time/date of visits, duration of use
Device OS and model information
Focus Data: Time spent in focus sessions, blocked app categories (processed locally)
Usage Analytics: App performance data, crash reports, and feature usage statistics
Information We Do NOT Collect

Precise location data
Content from blocked applications
Personal messages or communications
Browsing history or specific app usage details beyond blocking statistics
Some personally identifiable info (e.g. email, name, user ID) may be requested to improve experience and support.

iOS Screen Time API

Phone Jail uses Apple's Screen Time API to provide app blocking functionality. This allows us to:

Monitor and limit app usage on your device
Block access to selected apps during focus sessions
Provide usage analytics and insights
All Screen Time data is processed locally on your device and is not permanently stored or transmitted to our servers.

How We Use Your Information

We use the information we collect to:

Provide and maintain the Phone Jail app blocking functionality
Monitor and analyze usage to improve our service
Send technical notices and support messages
Detect and prevent technical issues
Provide customer support
Process payments and manage subscriptions (through third-party providers)
Data Storage and Processing

Your focus analytics, app blocking preferences, and usage statistics are primarily processed and stored locally on your device. Only aggregated, anonymized data is sent to our servers for service improvement purposes.

Data Categories

Data Linked to You:

Contact Information (email, if provided)
User Identifiers (anonymous user ID)
Data Not Linked to You:

Usage Data (app blocking patterns)
Diagnostics (crash reports, performance data)
Third Party Access

We may share anonymized data with services such as:

Google Play Services
Google Analytics for Firebase
Firebase Crashlytics
RevenueCat
Data may also be shared to comply with legal obligations or protect user safety.

Your Rights and Choices

Access and Control

Access Your Data: You can request a copy of your personal data
Update Your Information: You can update your account information at any time
Delete Your Data: You can request deletion of your personal data
Data Portability: You can request your data in a portable format
Opt-Out

You can stop all data collection by uninstalling the app from your device. You can also:

Disable analytics collection in app settings
Unsubscribe from marketing communications
Data Retention

User data is kept as long as the app is used, and a reasonable time after. When we no longer need to use your information, we will delete it from our systems and records or anonymize it. For deletion requests, email: smartclickdeveloper@gmail.com

Security

We use electronic and procedural safeguards to protect your data. These measures include:

Encryption of data in transit and at rest
Regular security assessments
Limited access to personal information
Secure development practices
International Data Transfers

Your information may be transferred to and processed in countries other than your country of residence. These countries may have data protection laws that are different from the laws of your country.

iOS App Store Privacy

This privacy policy complies with Apple App Store requirements. Our app's privacy details are also available on the App Store listing, including:

Data collection practices
Privacy nutrition labels
App permissions and their purposes
California Privacy Rights

If you are a California resident, you have specific rights regarding your personal information under the California Consumer Privacy Act (CCPA). These rights include:

The right to know what personal information we collect, use, disclose, and sell
The right to request deletion of your personal information
The right to opt-out of the sale of personal information (we do not sell personal information)
The right to non-discrimination for exercising your privacy rights
Changes

This policy may be updated. Please check this page regularly. Continued use means acceptance. We will notify you of any changes by updating the effective date.

Effective date: August 08, 2025

Contact Us

For any privacy-related questions, contact: smartclickdeveloper@gmail.com
"""
}
