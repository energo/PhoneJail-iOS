import SwiftUI

struct SlideToTurnOnView: View {
  @Binding var isBlocked: Bool
  @Binding var isStrictBlock: Bool
  
  @Environment(\.isEnabled) private var isEnabled
  
  @State private var offset: CGFloat = .zero
  @State private var widthOfSlide: CGFloat = .zero
  @State private var userDragging: Bool = false
  @State private var shakeTrigger: CGFloat = 0
  
  var drag: some Gesture {
    DragGesture()
      .onChanged { value in
        // Запрещаем отключение, если strict и блокировка уже активна
        if isStrictBlock && isBlocked {
          return
        }
        
        withAnimation {
          offset = max(0, value.translation.width)
          userDragging = true
          isBlocked = offset >= (widthOfSlide * 0.55)
        }
      }
      .onEnded { value in
        if isStrictBlock && isBlocked {
          return
        }
        
        withAnimation {
          userDragging = false
          if value.translation.width >= (widthOfSlide * 0.55) {
            offset = widthOfSlide - 10
            isBlocked = true
          } else {
            offset = .zero
            isBlocked = false
          }
        }
      }
  }
  
  //MARK: - Views
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Spacer()
        ZStack(alignment: .center) {
          HStack {
            Image(isBlocked ? .icMainButtonLocked : .icMainButton)
              .resizable()
              .frame(width: 72, height: 72)
              .padding(.horizontal, 6)
              .offset(x: offset)
              .gesture(isEnabled ? drag : nil)
            Spacer()
          }
          .frame(maxWidth: .infinity)
          .frame(height: 84)
          .background(
            RoundedRectangle(cornerRadius: 9999)
              .fill(Color.clear)
              .stroke(
                isBlocked
                ? AnyShapeStyle(Color.as_red)
                : AnyShapeStyle(Color.as_gradietn_main_button),
                lineWidth: 2
              )
          )
          .cornerRadius(9999)
          .scaleEffect(userDragging ? 0.99 : 1.0)
          .onTapGesture {
            guard isEnabled else { return }
            
            if isStrictBlock && isBlocked {
              shakeNow()
              return
            }
            
            withAnimation {
              userDragging = true
              offset = 20
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              withAnimation {
                userDragging = false
                offset = .zero
                isBlocked = false
              }
            }
          }
          
          if isBlocked  {
            lockedText
          } else {
            slideText
          }
        }
        .modifier(ShakeEffect(animatableData: shakeTrigger))
        .opacity(isEnabled ? 1.0 : 0.5)
        .onAppear {
          widthOfSlide = geometry.size.width - 50 - 24
          
          // Синхронизация offset с isUnlocked при появлении
          if isBlocked {
            offset = widthOfSlide - 10
            userDragging = false
          } else {
            offset = 0
            userDragging = false
          }
        }
        .onChangeWithOldValue(of: isBlocked) { oldValue, newValue in
          withAnimation {
            if newValue {
              offset = widthOfSlide - 10
              userDragging = false
            } else {
              offset = 0
              userDragging = false
            }
          }
        }
      }
    }
    .frame(height: 84)
  }
  
  private var slideText: some View {
    HStack {
      Spacer()
        .frame(maxWidth: 100)
      
      Text("Slide to Block")
        .opacity(userDragging ? 0.5 : 1.0)
        .foregroundStyle(.white)
        .font(.system(size: 13,
                      weight: .light))
      Spacer()
        .frame(maxWidth: 60)
      Image(.icLockButton)
        .resizable()
        .frame(width: 18, height: 20)
        .padding(.trailing, 16)
    }
  }
  
  private var lockedText: some View {
    HStack {
      Image(.icAppBlocked)
        .resizable()
        .frame(width: 24, height: 24)
        .padding(.leading, 16)
      
      Spacer()
        .frame(maxWidth: 60)
      Text(isStrictBlock ? "Strict blocked" : "Apps blocked")
        .opacity(userDragging ? 0.5 : 1.0)
        .foregroundStyle(Color.as_red)
        .font(.system(size: 16, weight: .light))
      Spacer()
        .frame(maxWidth: 100)
    }
  }
  
  private func shakeNow() {
    withAnimation(.default) {
      shakeTrigger += 1
    }
  }
}

//MARK: - Preview
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
          .fill(
            Color.white.opacity(0.07)
          )
      }
      .padding(.horizontal, 20)
    }
  )
}
