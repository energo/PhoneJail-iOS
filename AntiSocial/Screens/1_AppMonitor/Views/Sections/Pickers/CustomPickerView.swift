
import SwiftUI
public enum SegmentStyle {
  case styleOne
  case styleTwo
}

public struct CustomPickerView: View {
  var segmentWidth: CGFloat = 32.0
  
  @Binding var count: Int
  var values: ClosedRange<Int>
  var spacing: Double
  var steps: Int
  @State var isScrolling: Bool = false
  var style: SegmentStyle
  var selectedExtraText: String = ""
  
  //MARK: - Init Methods
  public init(count: Binding<Int>,
              from: Int,
              to: Int,
              spacing: Double = 24.0,
              steps: Int,
              style: SegmentStyle,
              selectedExtraText: String = "") {
    _count = count
    self.values = from...(style == .styleTwo ? (to * steps) : to)
    self.spacing = spacing
    self.steps = steps
    self.style = style
    self.selectedExtraText = selectedExtraText
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
                }
                proxy.scrollTo(count, anchor: .center)
              }
            }
          })
          .onChange(of: count) {old, newValue in
            // Trigger haptic feedback on count change
            HapticManager.shared.impact(style: .light)
          }
        })
      }
    }
    .frame(height: 40)
  }
}

#Preview {
  CustomPickerView(count: .constant(10), from: 0, to: 10, steps: 1, style: .styleOne)
}
