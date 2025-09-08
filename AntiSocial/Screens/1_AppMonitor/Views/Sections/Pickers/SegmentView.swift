

import SwiftUI

struct SegmentView: View {
  let values: ClosedRange<Int>
  let steps: Int
  let valueStep: Int
  let segmentWidth: CGFloat
  let style: SegmentStyle
  let selectedIndex: Int  // <-- Новый параметр
  var selectedExtraText: String = ""
  
  var body: some View {
    ForEach(values, id: \.self) { index in
      let isPrimary = (index % steps == .zero)
      let middleSteps = Double(steps) / 2
      let isMiddle = (Double(index) - middleSteps).truncatingRemainder(dividingBy: Double(steps)) == .zero
      let isSelected = index == selectedIndex // <-- Сравниваем
      
      Rectangle()
        .frame(
          width: segmentWidth,
          height: isPrimary ? 30.0 : (isMiddle ? 18.0 : 8.0)
        )
        .frame(maxHeight: 20.0, alignment: .bottom)
        .foregroundStyle(Color.clear) // Цвет по центру
        .id(index)
        .overlay {
          if isPrimary {
            HStack {
              Spacer()
              Text(text(index))
                .font(.system(size: 16, weight: .regular))
                .multilineTextAlignment(.center)
                .fixedSize()
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
              Spacer()
            }
          }
        }
    }
  }
  
  private func text(_ index: Int) -> String {
    let isSelected = index == selectedIndex // <-- Сравниваем
    let displayValue = style == .styleOne ? (index * valueStep) : ((index / steps) * valueStep)
    return "\(displayValue) \(isSelected ? selectedExtraText : "")"
  }
}
