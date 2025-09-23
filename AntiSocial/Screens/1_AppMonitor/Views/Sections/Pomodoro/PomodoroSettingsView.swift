//
//  PomodoroSettingsView.swift
//  AntiSocial
//
//  Created by Assistant on current date.
//

import SwiftUI
import FamilyControls

struct PomodoroSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: PomodoroViewModel
    @State private var showingAppPicker = false
    
    private let adaptive = AdaptiveValues.current
    
    // Focus duration options
    private let focusDurations = [5, 10, 15, 25, 30]
    
    // Break duration options
    private let breakDurations = [5, 10, 15, 25, 30]
    
    var body: some View {
        BGView(imageRsc: .bgMain) {
            VStack(spacing: 16) {
                headerView
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                
                separatorView
                    .padding(.horizontal, 32)
                
                ScrollView {
                    VStack(spacing: 16) {
                        focusDurationSection
                        separatorView
                        breakDurationSection
                        separatorView
                        strictBlockSection
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                saveButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .fullScreenCover(isPresented: $showingAppPicker) {
            FamilyActivityPickerWrapper(
                isPresented: $showingAppPicker,
                selection: $viewModel.selectionActivity
            )
        }
    }
    
    // MARK: - Header
  private var headerView: some View {
    HStack {
      HStack(spacing: 8) {
        Image(.icNavPomodoro)
          .resizable()
          .frame(width: 24, height: 24)
//          .padding(8)

        
        Text("Pomodoro Blocker")
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(Color.white)
      }
      
      Spacer()
      
      Button(action: {
        self.isPresented = false
      }) {
        Image(.icNavClose)
          .frame(width: 24, height: 24)
      }
    }
  }
    
    // MARK: - Focus Duration Section
    
  private var focusDurationSection: some View {
    VStack(alignment: .center, spacing: 16) {
      HStack(spacing: 0) {
        Text("Select Focus Duration")
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(.white)
       Spacer()
      }
      
       // Duration buttons
       HStack(spacing: 0) {
         ForEach(focusDurations, id: \.self) { duration in
           durationButton(
             duration: duration,
             isSelected: viewModel.focusDuration == duration,
             action: { viewModel.focusDuration = duration }
           )
         }
       }
       .frame(maxWidth: .infinity)
      
      // Duration input field
      durationInputField(
        value: $viewModel.focusDuration,
        range: 5...60
      )
    }
  }
    
    // MARK: - Break Duration Section
    
    private var breakDurationSection: some View {
        VStack(alignment: .center, spacing: 16) {
          HStack(spacing: 0) {
            Text("Select Break Duration")
              .font(.system(size: 16, weight: .regular))
              .foregroundColor(.white)
            
            Spacer()
          }
            
             // Duration buttons
             HStack(spacing: 0) {
                 ForEach(breakDurations, id: \.self) { duration in
                     durationButton(
                         duration: duration,
                         isSelected: viewModel.breakDuration == duration,
                         action: { viewModel.breakDuration = duration }
                     )
                 }
             }
             .frame(maxWidth: .infinity)
            
            // Duration input field
            durationInputField(
                value: $viewModel.breakDuration,
                range: 5...30
            )
        }
    }
    
    // MARK: - Strict Block Section
    
    private var strictBlockSection: some View {
        HStack {
            Text("Strict Block")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $viewModel.isStrictBlock)
                .toggleStyle(SwitchToggleStyle(tint: .purple))
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: {
            viewModel.saveSettings()
            isPresented = false
        }) {
            HStack {
                Spacer()
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(height: 50)
            .background(Color.as_gradietn_button_purchase)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
    
    // MARK: - Helper Views
   private func durationButton(
       duration: Int,
       isSelected: Bool,
       action: @escaping () -> Void
   ) -> some View {
     Button(action: action) {
       VStack(spacing: 0) {
         Text("\(duration)")
           .font(.system(size: 18, weight: .bold))
           .foregroundColor(isSelected ? .black : .white)
         Text("Min")
           .font(.system(size: 12, weight: .regular))
           .foregroundColor(isSelected ? .black : .white)
       }
       .frame(width: 54, height: 54)
       .background(
         Circle()
           .fill(isSelected ? Color.white : Color.white.opacity(0.1))
       )
     }
     .frame(maxWidth: .infinity)
   }
    
  private func durationInputField(
      value: Binding<Int>,
      range: ClosedRange<Int>
  ) -> some View {
      HStack {
          Text("Duration")
              .font(.system(size: 16, weight: .regular))
              .foregroundColor(.white)
          
          Spacer()
          
        Text("\(value.wrappedValue) Min")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(minWidth: 80)

          HStack(spacing: 0) {
              Button(action: {
                  if value.wrappedValue > range.lowerBound {
                      value.wrappedValue -= 1
                  }
              }) {
                Image(.icMinus)
                  .resizable()
                  .frame(width: 20, height: 20)
              }
                            
              Rectangle()
                  .fill(Color.as_white_light.opacity(0.2))
                  .frame(width: 1, height: 20)
                  .padding(.horizontal, 10)
              
              Button(action: {
                  if value.wrappedValue < range.upperBound {
                      value.wrappedValue += 1
                  }
              }) {
                Image(.icPlus)
                  .resizable()
                  .frame(width: 20, height: 20)
              }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background(Color.white.opacity(0.07))
          .clipShape(RoundedRectangle(cornerRadius: 32))
          .padding(.vertical, 8)

      }
      .padding(.horizontal, 16)
      .background(Color.white.opacity(0.07))
      .clipShape(RoundedRectangle(cornerRadius: 32))
  }

//    private func durationInputField(
//        value: Binding<Int>,
//        range: ClosedRange<Int>
//    ) -> some View {
//        HStack {
//            Text("Duration")
//                .font(.system(size: 16, weight: .regular))
//                .foregroundColor(.white)
//            
//            Spacer()
//            
//            HStack(spacing: 0) {
//                Button(action: {
//                    if value.wrappedValue > range.lowerBound {
//                        value.wrappedValue -= 1
//                    }
//                }) {
//                    Text("-")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(.white)
//                        .frame(width: 30, height: 30)
//                }
//                
//                Rectangle()
//                    .fill(Color.white.opacity(0.2))
//                    .frame(width: 1, height: 20)
//                
//                Text("\(value.wrappedValue) Min")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
//                    .frame(minWidth: 80)
//                
//                Rectangle()
//                    .fill(Color.white.opacity(0.2))
//                    .frame(width: 1, height: 20)
//                
//                Button(action: {
//                    if value.wrappedValue < range.upperBound {
//                        value.wrappedValue += 1
//                    }
//                }) {
//                    Text("+")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(.white)
//                        .frame(width: 30, height: 30)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//            .background(Color.white.opacity(0.07))
//            .clipShape(RoundedRectangle(cornerRadius: 30))
//        }
//    }
    
    private var separatorView: some View {
        SeparatorView()
    }
}

// MARK: - Preview
#Preview {
    PomodoroSettingsView(
        isPresented: .constant(true),
        viewModel: PomodoroViewModel()
    )
}
