
import SwiftUI
public enum SegmentStyle {
  case styleOne
  case styleTwo
}

public struct CustomPickerView: View {
  var segmentWidth: CGFloat = 32.0
  
  @Binding var actualValue: Int
  var values: ClosedRange<Int>
  var spacing: Double
  var steps: Int
  var valueStep: Int
  @State private var count: Int = 0
  @State var isScrolling: Bool = false
  var style: SegmentStyle
  var selectedExtraText: String = ""
  
  // MARK: - Conversion Methods
  /// Конвертирует реальное значение в индекс
  private func valueToIndex(_ value: Int) -> Int {
    return value / valueStep
  }
  
  /// Конвертирует индекс в реальное значение
  private func indexToValue(_ index: Int) -> Int {
    return index * valueStep
  }
  
  //MARK: - Init Methods
  
  /// Основной инициализатор для работы с реальными значениями
  public init(actualValue: Binding<Int>,
              fromValue: Int,
              toValue: Int,
              spacing: Double = 24.0,
              steps: Int,
              valueStep: Int = 1,
              style: SegmentStyle,
              selectedExtraText: String = "") {
    _actualValue = actualValue
    self.valueStep = valueStep
    self.spacing = spacing
    self.steps = steps
    self.style = style
    self.selectedExtraText = selectedExtraText
    
    // Создаем values с учетом valueStep
    let fromIndex = fromValue / valueStep
    let toIndex = style == .styleTwo ? ((toValue * steps) / valueStep) : (toValue / valueStep)
    self.values = fromIndex...(toIndex)
    
    // Инициализируем count на основе actualValue
    self.count = actualValue.wrappedValue / valueStep
  }
  
  public var body: some View {
    ZStack {
      GeometryReader { geo in
        ScrollViewReader(content: { proxy in
          ScrollView(.horizontal) {
            ZStack {
              ScrollViewOffsetReader(onScrollingStarted: {
                isScrolling = true
              }, onScrollingFinished: {
                isScrolling = false
              })
              
              HStack(spacing: spacing) {
                SegmentView(
                  values: values,
                  steps: steps,
                  valueStep: valueStep,
                  segmentWidth: segmentWidth,
                  style: style,
                  selectedIndex: count,
                  selectedExtraText: selectedExtraText// <-- Передаём текущий count
                )
              }
              .frame(height: geo.size.height)
              .scrollTargetLayout()
            }
          }
          .scrollIndicators(.hidden)
          .safeAreaPadding(.horizontal, geo.size.width / 2.0)
          .scrollTargetBehavior(.viewAligned)
          .onAppear {
            // Синхронизируем count с actualValue при появлении
            count = valueToIndex(actualValue)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              withAnimation {
                proxy.scrollTo(count, anchor: .center)
              }
            }
          }
          .scrollPosition(
            id: .init(
              get: {
                return count
              },
              set: { value, transaction in
                if let value {
                  count = value
                  actualValue = indexToValue(value)
                }
              }
            )
          )
          .onChange(of: isScrolling, { oldValue, newValue in
            if newValue == false && style == .styleTwo {
              let indexValue: Double = Double(count) / Double(steps)
              let nextItem = indexValue.rounded()
              let newIndex = nextItem * Double(steps)
              
              withAnimation{
                if count != Int(newIndex) {
                  count = Int(newIndex)
                  actualValue = indexToValue(Int(newIndex))
                }
                proxy.scrollTo(count, anchor: .center)
              }
            }
          })
          .onChange(of: count) {old, newValue in
            // Trigger haptic feedback on count change
            HapticManager.shared.impact(style: .light)
          }
          .onChange(of: actualValue) { oldValue, newValue in
            // Синхронизируем count при изменении actualValue извне
            count = valueToIndex(newValue)
          }
        })
      }
    }
    .frame(height: 40)
  }
}

#Preview {
  VStack(spacing: 20) {
    // Пример с шагом 1 (по умолчанию)
    CustomPickerView(actualValue: .constant(10), fromValue: 0, toValue: 20, steps: 1, style: .styleOne)
    
    // Пример с шагом 5
    CustomPickerView(actualValue: .constant(25), fromValue: 0, toValue: 100, steps: 1, valueStep: 5, style: .styleOne)
    
    // Пример с styleTwo и дополнительным текстом
    CustomPickerView(actualValue: .constant(30), fromValue: 0, toValue: 60, steps: 1, valueStep: 5, style: .styleTwo, selectedExtraText: "мин")
  }
}
