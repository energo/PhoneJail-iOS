import SwiftUI


struct SlideToTurnOnView: View {
  @Binding var isBlocked: Bool
  @Binding var isStrictBlock: Bool

  var isLimitReached: Bool = false
  var onBlockingStateChanged: ((Bool) -> Void)?
  var onPurchaseTap: (() -> Void)?
  
  @Environment(\.isEnabled) private var isEnabled
  
  @State private var offset: CGFloat = .zero
  @State private var widthOfSlide: CGFloat = .zero
  @State private var userDragging: Bool = false
  @State private var shakeTrigger: CGFloat = 0
  @State private var isBlockedPreview: Bool = false
  @State private var slideProgress: CGFloat = 0
  @State private var lastHapticOffset: CGFloat = 0
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Spacer()
        slider
          .modifier(ShakeEffect(animatableData: shakeTrigger))
          .opacity(isEnabled ? 1.0 : 0.5)
          .onAppear { setupInitialState(in: geometry) }
          .onChangeWithOldValue(of: isBlocked) { _, newValue in
            updateUI(for: newValue)
          }
      }
    }
    .frame(height: 84)
  }
}

// MARK: - Subviews

private extension SlideToTurnOnView {
  var slider: some View {
    ZStack(alignment: .center) {
      sliderTrack
      sliderTextOverlay
    }
  }
  
  var sliderTrack: some View {
    HStack {
      if !isLimitReached {
        sliderThumb
      }
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .frame(height: 84)
    .background(sliderBackground)
    .cornerRadius(9999)
    .scaleEffect(userDragging ? 0.99 : 1.0)
  }
  
  var sliderThumb: some View {
    Image(isBlockedPreview ? .icMainButtonLocked : .icMainButton)
      .resizable()
      .frame(width: 72, height: 72)
      .padding(.horizontal, 6)
      .offset(x: offset)
      .gesture(isEnabled ? dragGesture : nil)
  }
  
  var sliderBackground: some View {
    RoundedRectangle(cornerRadius: 9999)
      .fill(Color.clear)
      .stroke(
        slideProgress >= 0.55
        ? AnyShapeStyle(Color.as_red)
        : AnyShapeStyle(Color.as_gradietn_main_button),
        lineWidth: 4
      )
      .animation(.easeInOut(duration: 0.25), value: slideProgress)
  }
  
  var sliderTextOverlay: some View {
    Group {
      if isBlockedPreview {
        lockedText
      } else {
        slideText
      }
    }
    .onTapGesture {
      if isLimitReached {
        handleTap()
      }
    }
  }
  
  var slideText: some View {
    HStack {
      if isLimitReached {
        Spacer()
        Image(.icLockPurchase)
          .resizable()
          .frame(width: 18, height: 20)
        Text("Purchase to unlock")
          .foregroundStyle(.white)
          .font(.system(size: 16, weight: .light))
        Spacer()
      } else {
        Spacer().frame(maxWidth: 100)
        
        Text("Slide to Block")
          .opacity(userDragging ? 0.5 : 1.0)
          .foregroundStyle(.white)
          .font(.system(size: 16, weight: .light))
        
        Spacer().frame(maxWidth: 60)
        
        Image(.icLockButton)
          .resizable()
          .frame(width: 18, height: 20)
          .padding(.trailing, 16)
      }
    }
  }
  
  var lockedText: some View {
    HStack {
      Image(.icAppBlocked)
        .resizable()
        .frame(width: 24, height: 24)
        .padding(.leading, 16)
      
      Spacer().frame(maxWidth: 60)
      
      Text(isStrictBlock ? "Strict blocked" : "Apps blocked")
        .opacity(userDragging ? 0.5 : 1.0)
        .foregroundStyle(Color.as_red)
        .font(.system(size: 16, weight: .light))
      
      Spacer().frame(maxWidth: 100)
    }
  }
}

// MARK: - Gestures

private extension SlideToTurnOnView {
  var dragGesture: some Gesture {
    DragGesture()
      .onChanged(handleDragChanged)
      .onEnded(handleDragEnded)
  }
  
  func handleDragChanged(_ value: DragGesture.Value) {
    guard !isLimitReached else { return }
    guard !(isStrictBlock && isBlocked) else { return }
    
    withAnimation {
      offset = max(0, value.translation.width)
      userDragging = true
      
      let progress = min(offset / (widthOfSlide - 10), 1)
      slideProgress = progress
      let wasBlockedPreview = isBlockedPreview
      isBlockedPreview = progress >= 0.55
      
      // Haptic feedback for every pixel of movement
      let pixelThreshold: CGFloat = 1.0 // Trigger haptic every 1 pixel
      if abs(offset - lastHapticOffset) >= pixelThreshold {
        // Use selection feedback for continuous subtle vibration on every pixel
        HapticManager.shared.selection()
        lastHapticOffset = offset
      }
      
      // Additional strong feedback when crossing the threshold
      if isBlockedPreview != wasBlockedPreview {
        HapticManager.shared.impact(style: .heavy)
      }
    }
  }
  
  func handleDragEnded(_ value: DragGesture.Value) {
    guard !isLimitReached else { return }
    guard !(isStrictBlock && isBlocked) else {
      shakeNow()
      return
    }
    
    let shouldBlock = value.translation.width >= (widthOfSlide * 0.55)
    
    // Reset haptic offset for next drag
    lastHapticOffset = 0
    
    // Update UI immediately with animation
    withAnimation {
      userDragging = false
      offset = shouldBlock ? (widthOfSlide - 10) : .zero
      slideProgress = shouldBlock ? 1 : 0
      isBlockedPreview = shouldBlock
      isBlocked = shouldBlock
    }
    
    // Haptic feedback immediately
    if shouldBlock {
      // Locking - success haptic pattern
      HapticManager.shared.notification(type: .success)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        HapticManager.shared.impact(style: .rigid)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        HapticManager.shared.impact(style: .heavy)
      }
    } else {
      // Unlocking - warning haptic pattern  
      HapticManager.shared.notification(type: .warning)
    }
    
    // Call the blocking state handler asynchronously without blocking animation
    DispatchQueue.main.async {
      onBlockingStateChanged?(shouldBlock)
    }
  }
  
  func handleTap() {
    guard isEnabled else { return }

    if isLimitReached {
      HapticManager.shared.impact(style: .light)
      onPurchaseTap?()
      return
    }
    
    
    if isStrictBlock && isBlocked {
      shakeNow()
      return
    }
    
    // Animate the tap feedback
    withAnimation(.easeOut(duration: 0.2)) {
      userDragging = true
      offset = 20
    }
    
    // Return to initial position and update state
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      withAnimation(.easeInOut(duration: 0.3)) {
        userDragging = false
        offset = .zero
        slideProgress = 0
        isBlockedPreview = false
        isBlocked = false
      }
      
      // Call the blocking state handler asynchronously without blocking animation
      DispatchQueue.main.async {
        onBlockingStateChanged?(false)
      }
    }
  }
}

// MARK: - Helpers

private extension SlideToTurnOnView {
  func shakeNow() {
    HapticManager.shared.notification(type: .error)
    withAnimation(.default) {
      shakeTrigger += 1
    }
  }
  
  func setupInitialState(in geometry: GeometryProxy) {
    widthOfSlide = geometry.size.width - 50 - 24
    offset = isBlocked ? (widthOfSlide - 10) : 0
    userDragging = false
    isBlockedPreview = isBlocked
    slideProgress = isBlocked ? 1 : 0
  }
  
  func updateUI(for newValue: Bool) {
    withAnimation {
      offset = newValue ? (widthOfSlide - 10) : 0
      userDragging = false
      isBlockedPreview = newValue
      slideProgress = newValue ? 1 : 0
    }
  }
}

// MARK: - Color Interpolation
private extension Color {
  static func interpolate(from: Color, to: Color, progress: CGFloat) -> Color {
    let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
    let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
    
    let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * progress
    let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * progress
    let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * progress
    let a = fromComponents[3] + (toComponents[3] - fromComponents[3]) * progress
    
    return Color(red: r, green: g, blue: b, opacity: a)
  }
}

// MARK: - Preview
#Preview {
  @Previewable @State var isLocked: Bool = false
  @Previewable @State var isStrict: Bool = false
  
  VStack {
    SlideToTurnOnView(isBlocked: $isLocked, isStrictBlock: $isStrict)
  }.background(
    ZStack {
      Image(.bgMain)
      VStack {
        BackdropBlurView(isBlack: false, radius: 10)
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.white.opacity(0.07))
      }
      .padding(.horizontal, 20)
    }
  )
}
