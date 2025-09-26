//
//  AllAppsActivityView.swift
//  DeviceReportExtension
//

import SwiftUI
import DeviceActivity

extension DeviceActivityReport.Context {
  static let appsActivity = Self("Apps Activity")
}

struct AppsActivityView: View {
  
  @Environment(\.dismiss) private var dismiss
  @Binding var currentFilter: DeviceActivityFilter
  let context: DeviceActivityReport.Context = .appsActivity

  var body: some View {
    BGView(imageRsc: .bgMain, withBGBlur: true) {
      VStack(spacing: 0) {
        
        HStack() {
          Spacer()
          closeButton
        }
        
        VStack(spacing: 16) {
          HStack(spacing: 16) {
            Image("ic_watch")
              .resizable()
              .renderingMode(.template)
              .foregroundStyle(.white)
              .frame(width: 14, height: 20, alignment: .bottom)
            
            Text("Apps screen time")
              .font(.title2.bold())
              .foregroundColor(.white)
            
            Spacer()
            
          }
          .padding(.top, 12)
          
          separatorView
        }
        
        ZStack {
          DeviceActivityReport(context, filter: currentFilter)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(bgBlur)
        .padding(.top, 16)
      }
      .padding(.horizontal, 32)
    }
  }
  
  private var closeButton: some View {
    Button(action: {
      dismiss()
    }) {
      ZStack {
        Circle()
          .fill(
            .white.opacity(0.07)
          )
          .frame(width: 28, height: 28)
        
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.white)
      }
    }
  }
  
  private var separatorView: some View {
    Rectangle()
      .fill(Color(hex: "D9D9D9").opacity(0.23))
      .frame(height: 0.5)
  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
}


