//
//  TotalActivityReport.swift
//  DeviceReportExtension
//
//  Created by D C on 01.07.2025.
//

import DeviceActivity
import SwiftUI

//func containsIPhone(_ name: String) -> Bool {
//  return name.range(of: "iPhone", options: .caseInsensitive) != nil
//}


struct TotalActivityReport: DeviceActivityReportScene {
  
  // Define which context your scene will represent.
  let context: DeviceActivityReport.Context = .totalActivity
  
  // Define the custom configuration and the resulting view for this report.
  let content: (ActivityReport) -> ScreenTimeSectionView
  
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
    // Reformat the data into a configuration that can be used to create
    // the report's view.
    var list: [AppDeviceActivity] = []
    var topList: [AppDeviceActivity] = []
    
    let totalActivityDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
      $0 + $1.totalActivityDuration
    })
    var totalPickups = 0
    var longestActivity: DateInterval?
    var firstPickup: Date?
    var categories: [String] = []
    
    for await d in data {
      for await a in d.activitySegments {
        totalPickups = a.totalPickupsWithoutApplicationActivity
        longestActivity = a.longestActivity
        firstPickup = a.firstPickup
        
        
        for await c in a.categories {
          categories.append((c.category.localizedDisplayName)!)
          
          for await ap in c.applications {
            let appName = (ap.application.localizedDisplayName ?? "nil")
            let bundle = (ap.application.bundleIdentifier ?? "nil")
            
            
            if appName == bundle{
              continue
            }
            
            let duration = Int(ap.totalActivityDuration)
            let durationInterval = ap.totalActivityDuration
            let category = c.category.localizedDisplayName!
            let token = ap.application.token!
            
            let numberOfHours = duration / 3600
            let numberOfMins = (duration % 3600) / 60
            var formatedDuration = ""
            
            if numberOfHours == 0 {
              if numberOfMins != 1{
                formatedDuration = "\(numberOfMins)m"
              }else{
                formatedDuration = "\(numberOfMins)m"
              }
            } else if numberOfHours == 1 {
              if numberOfMins != 1{
                formatedDuration = "\(numberOfHours)h \(numberOfMins)m"
              } else {
                formatedDuration = "\(numberOfHours)h \(numberOfMins)m"
              }
            } else {
              if numberOfMins != 1 {
                formatedDuration = "\(numberOfHours)h \(numberOfMins)m"
              } else {
                formatedDuration = "\(numberOfHours)h \(numberOfMins)m"
              }
            }
            
            let numberOfPickups = ap.numberOfPickups
            let notifs = ap.numberOfNotifications
            

            let app = AppDeviceActivity(id: bundle,
                                        token: token,
                                        displayName: appName,
                                        duration: formatedDuration,
                                        durationInterval: durationInterval,
                                        numberOfPickups: numberOfPickups,
                                        category: category,
                                        numberOfNotifs: notifs)
            list.append(app)
          }
        }
      }
    }
    
    topList = list
    topList = Array(list.sorted(by: sortApps).prefix(3))
    
    return ActivityReport(totalDuration: totalActivityDuration,
                          totalPickupsWithoutApplicationActivity: totalPickups,
                          longestActivity: longestActivity,
                          firstPickup: firstPickup,
                          categories: categories,
                          apps: list,
                          topApps: topList)
  }
  
  func sortApps(this:AppDeviceActivity, that:AppDeviceActivity) -> Bool {
    return this.durationInterval > that.durationInterval
  }
}

//struct TotalActivityReport: DeviceActivityReportScene {
//  let context: DeviceActivityReport.Context = .totalActivity
//
//  let content: (String) -> TotalActivityView
//
//  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
//    let formatter = DateComponentsFormatter()
//    formatter.allowedUnits = [.day, .hour, .minute, .second]
//    formatter.unitsStyle = .abbreviated
//    formatter.zeroFormattingBehavior = .dropAll
//
//    let thisDevice = UIDevice.current.model
//
//    guard let singleDeviceData = await data.first(where: { containsIPhone(String($0.device.name!)) }) else {
//      return "This device data is not available right now\n thisDevice:\(thisDevice) \n"
//    }
//
//    let totalActivityDuration = await singleDeviceData.activitySegments.reduce(0) { total, segment in
//      total + segment.totalActivityDuration
//    }
//
//    var appNames = [String]()
//    appNames.append("\(thisDevice),Time: \(String(describing: formatter.string(from: totalActivityDuration) ?? "Total time not found"))")
//
//    for await activitySegment in singleDeviceData.activitySegments {
//      for await category in activitySegment.categories {
//        for await app in category.applications {
//          let appName = app.application.localizedDisplayName ?? "nil"
//          let appTime = formatter.string(from: app.totalActivityDuration) ?? "No Time Found"
//          appNames.append("\(appName),Time:\(appTime)")
//        }
//      }
//    }
//
//    let res = appNames.joined(separator: "\n")
//    return res.isEmpty ? "No activity data" : res
//  }
//}
