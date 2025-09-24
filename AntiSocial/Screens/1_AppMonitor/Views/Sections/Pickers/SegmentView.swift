

import SwiftUI

struct SegmentView: View {
  let values: ClosedRange<Int>
  let steps: Int
  let valueStep: Int
  let style: SegmentStyle
  let selectedIndex: Int  // <-- Новый параметр
  var selectedExtraText: String = ""
  
  var body: some View {
    contentView
  }
  
  // MARK: - Private views
  private var contentView: some View {
    ForEach(values, id: \.self) { index in
      cellView(for: index)
    }
  }
  
  @ViewBuilder
  private func cellView(for index: Int) -> some View {
    switch style {
      case .styleOne, .styleTwo:
        largeCellView(for: index)
      case .styleSlim:
        tinyCellView(for: index)
    }
    
  }
  
  @ViewBuilder
  private func largeCellView(for index: Int) -> some View {
    let isPrimary = (index % steps == .zero)
    let middleSteps = Double(steps) / 2
    let isMiddle = (Double(index) - middleSteps).truncatingRemainder(dividingBy: Double(steps)) == .zero
    let isSelected = index == selectedIndex // <-- Сравниваем
    
    Rectangle()
      .frame(
        width: style.lineWidth,
        height: isPrimary ? 30.0 : (isMiddle ? 18.0 : 8.0)
      )
      .frame(maxHeight: 20.0, alignment: .bottom)
      .foregroundStyle(Color.clear) // Цвет по центру
      .id(index)
      .overlay {
        cellOverlayView(index: index, isPrimary: isPrimary, isSelected: isSelected)
      }
  }
  
  @ViewBuilder
  private func tinyCellView(for index: Int) -> some View {
    let isDividedByFive = (index % 5 == .zero)
    let distanceToSelected = abs(Double(selectedIndex) - Double(index))
    let foregroundColor = {
      if distanceToSelected == 0 {
        return Color.white
      } else if distanceToSelected <= 5 {
        return Color.white.opacity(0.4)
      } else {
        return Color.white.opacity(0.2)
      }
    }()
    let lineWidth = style.lineWidth
    
    VStack(spacing: 6) {
      RoundedRectangle(cornerRadius: lineWidth / 2)
        .frame(
          width: lineWidth,
          height: isDividedByFive ? 40 : 20
        )
        .frame(maxHeight: 40, alignment: .bottom)
      tinyCellTextView(index: index, isShown: isDividedByFive, color: foregroundColor)
    }
    .foregroundStyle(foregroundColor)
    .id(index)
  }
  
  @ViewBuilder
  private func cellOverlayView(index: Int, isPrimary: Bool, isSelected: Bool) -> some View {
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
  
  @ViewBuilder
  private func tinyCellTextView(index: Int, isShown: Bool, color: Color) -> some View {
    let width = style.segmentWidth
    if isShown {
      Text("\(indexTextValue(index))")
        .font(.system(size: 8))
        .foregroundStyle(color)
        .frame(width: width, height: 10, alignment: .center)
    } else {
      Spacer()
        .frame(width: width, height: 10)
    }
  }
  
  private func indexTextValue(_ index: Int) -> Int {
    style == .styleOne ? (index * valueStep) : ((index / steps) * valueStep)
  }
  
  private func text(_ index: Int) -> String {
    let isSelected = index == selectedIndex // <-- Сравниваем
    let displayValue = indexTextValue(index)
    return "\(displayValue) \(isSelected ? selectedExtraText : "")"
  }
}
