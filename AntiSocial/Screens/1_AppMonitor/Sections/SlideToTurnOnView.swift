//
//  ContentView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//


import SwiftUI

struct SlideToTurnOnView: View {
  @Binding var isUnlocked: Bool
  
  @State var offset: CGFloat = .zero
  @State var widthOfSlide: CGFloat = .zero
  @State var userDragging: Bool = false
  
  var drag: some Gesture {
    DragGesture()
      .onChanged { value in
        withAnimation {
          offset = max(0, value.translation.width)
          userDragging = true
          isUnlocked = offset >= (widthOfSlide * 0.55)
        }
      }
      .onEnded { value in
        withAnimation {
          userDragging = false
          if value.translation.width >= (widthOfSlide * 0.55) {
            offset = widthOfSlide - 10
            isUnlocked = true
          } else {
            offset = .zero
            isUnlocked = false
          }
        }
      }
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Spacer()
        ZStack(alignment: .center) {
          HStack {
            Image(isUnlocked ? .icMainButtonLocked : .icMainButton)
              .resizable()
              .frame(width: 72, height: 72)
              .padding(.horizontal, 6)
              .offset(x: offset)
              .gesture(drag)
            Spacer()
          }
          .frame(maxWidth: .infinity)
          .frame(height: 84)
          .background(
            RoundedRectangle(cornerRadius: 9999)
              .fill(Color.clear)
              .stroke(
                isUnlocked
                ? AnyShapeStyle(Color.as_green)
                : AnyShapeStyle(Color.as_gradietn_main_button),
                lineWidth: 2
              )
          )
          .cornerRadius(9999)
          .scaleEffect(userDragging ? 0.99 : 1.0)
          .onTapGesture {
            withAnimation {
              userDragging = true
              offset = 20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              withAnimation {
                userDragging = false
                offset = .zero
                isUnlocked = false
              }
            }
          }
          
          if isUnlocked  {
            lockedText
          } else {
            slideText
          }
        }
        .onAppear {
          widthOfSlide = geometry.size.width - 50 - 24
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
      Image(.icBook)
        .resizable()
        .frame(width: 18, height: 20)
        .padding(.leading, 16)
      
      Spacer()
        .frame(maxWidth: 60)
      Text("News blocked")
        .opacity(userDragging ? 0.5 : 1.0)
        .foregroundStyle(.white)
        .font(.system(size: 13,
                      weight: .light))
      Spacer()
        .frame(maxWidth: 100)
    }
  }
}

//MARK: - Preview
#Preview {
  @Previewable @State var isLocked: Bool = false
  
  VStack {
    SlideToTurnOnView(isUnlocked: $isLocked)
  }.background(
    ZStack {
      Image(.bgMain)
      VStack {
        BackdropBlurView(isBlack: false, radius: 10)
        RoundedRectangle(cornerRadius: 20)
          .fill(
            //          Color(hex: "A7A7A7").opacity(0.2)
            Color.white.opacity(0.07)
          )
      }
      .padding(.horizontal, 20)
    }
  )
}
