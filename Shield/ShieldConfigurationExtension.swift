//
//  ShieldConfigurationExtension.swift
//  Shield
//
//  Created by D C on 30.06.2025.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.

//TODO: Try to show time remaining via SharedData app.groups 
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: UIColor.black.withAlphaComponent(0.7),
      icon: UIImage(named: "ic_lock"),
      title: .init(text: "\(application.localizedDisplayName ?? "")\nIs Blocked By Phone Jail", color: .white),
      subtitle: .init(text: "", color: .white),
      primaryButtonLabel: .init(text: "Close", color: .white),
      primaryButtonBackgroundColor: .white.withAlphaComponent(0.2),
    )
  }
  
  override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: UIColor.black.withAlphaComponent(0.7),
      icon: UIImage(named: "ic_lock"),
      title: .init(text: "\(application.localizedDisplayName ?? "")\nIs Blocked By Phone Jail", color: .white),
      subtitle: .init(text: "", color: .white),
      primaryButtonLabel: .init(text: "Close", color: .white),
      primaryButtonBackgroundColor: .white.withAlphaComponent(0.2),
    )
  }
  
  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    // Customize the shield as needed for web domains.
    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: UIColor.black.withAlphaComponent(0.7),
      icon: UIImage(named: "ic_lock"),
      title: .init(text: "Blocked By Phone Jail", color: .white),
      subtitle: .init(text: "", color: .white),
      primaryButtonLabel: .init(text: "Close", color: .white),
      primaryButtonBackgroundColor: .white.withAlphaComponent(0.2),
    )
  }
  
  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
    // Customize the shield as needed for web domains shielded because of their category.
    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: UIColor.black.withAlphaComponent(0.7),
      icon: UIImage(named: "ic_lock"),
      title: .init(text: "Blocked By Phone Jail", color: .white),
      subtitle: .init(text: "", color: .white),
      primaryButtonLabel: .init(text: "Close", color: .white),
      primaryButtonBackgroundColor: .white.withAlphaComponent(0.2),
    )
  }
}
