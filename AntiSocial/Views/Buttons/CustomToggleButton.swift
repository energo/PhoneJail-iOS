//
//  CustomToggleButton.swift
//  AntiSocial
//
//  Created by Assistant on current date.
//

import SwiftUI

struct CustomToggleButton: View {
  @Binding var isOn: Bool

  var onText: String = "Enabled"
  var offText: String = "Disabled"
  var onColor: Color = .as_light_green
  var offColor: Color = .as_red

  var hapticFeedback: Bool = true
  var onAction: (() -> Void)? = nil
  var offAction: (() -> Void)? = nil
  
  // Shake effect parameters
  var shouldValidate: Bool = false
  var validationCheck: (() -> Bool)? = nil
  @State private var shakeTrigger: CGFloat = 0

  var height: CGFloat = 34
  var textGap: CGFloat = 8      // ← минимальный отступ между шайбой и текстом (4/8/16)
  var cornerRadius: CGFloat { height / 2 }

  var body: some View {
    Button {
      // Check validation if needed
      if shouldValidate && !isOn {
        if let validationCheck = validationCheck, !validationCheck() {
          // Validation failed - trigger shake effect
          triggerShakeEffect()
          return
        }
      }
      
      if hapticFeedback {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      }
      withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
        isOn.toggle()
      }
      (isOn ? onAction : offAction)?()
    } label: {
      GeometryReader { geo in
        let pad: CGFloat = 4
        let knob = height - pad * 2
        let travel = max(0, geo.size.width - pad * 2 - knob)
        let x = isOn ? (pad + travel) : pad
        let edgeGap: CGFloat = 16

        ZStack {
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(isOn ? onColor : offColor, lineWidth: 2)
            .animation(.easeInOut(duration: 0.2), value: isOn)


          Text(isOn ? onText : offText)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(isOn ? onColor : offColor)
            .frame(maxWidth: .infinity,
                   alignment: isOn ? .leading : .trailing) // противоположная сторона
            // Если шайба справа → текст слева: слева edgeGap, справа место под шайбу
            // Если шайба слева → текст справа: справа edgeGap, слева место под шайбу
            .padding(.leading,  isOn ? edgeGap : (knob + textGap))
            .padding(.trailing, isOn ? (knob + textGap) : edgeGap)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .animation(.easeInOut(duration: 0.22), value: isOn)

          // Шайба
          Circle()
            .fill(isOn ? Color.as_gradient_green : Color.as_gradietn_main_red_button)
            .frame(width: knob, height: knob)
            .overlay(
              Image(systemName: isOn ? "checkmark" : "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.15), value: isOn)
            )
            .offset(x: x - (geo.size.width / 2) + knob / 2)
            .animation(.spring(response: 0.38, dampingFraction: 0.9), value: isOn)
            .shadow(radius: 1)
        }
        .contentShape(Rectangle())
      }
      .frame(height: height)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isOn ? onText : offText)
    .accessibilityAddTraits(.isButton)
    .modifier(ShakeEffect(animatableData: shakeTrigger))
  }
  
  private func triggerShakeEffect() {
    HapticManager.shared.notification(type: .error)
    withAnimation(.default) {
      shakeTrigger += 1
    }
  }
}


// MARK: - Preview
#Preview {
  @Previewable @State var value = false
  BGView {
    VStack(spacing: 24) {
      CustomToggleButton(isOn: $value,
                         onText: "On",
                         offText: "Off")
        .frame(width: 80)
      
      CustomToggleButton(
        isOn: $value,
        onText: "Active",
        offText: "Disabled",
      )
      .frame(width: 150)


      CustomToggleButton(
        isOn: $value,
        onText: "Active",
        offText: "Disabled",
        height: 48
      )
      .frame(width: 180)
    }
  }
//  .padding()
//  .background(Color.gray.opacity(0.15))
}
