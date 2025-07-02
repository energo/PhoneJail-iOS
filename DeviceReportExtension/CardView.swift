//
//  CardView.swift
//  AntiSocial
//
//  Created by D C on 02.07.2025.
//

import SwiftUI
import DeviceActivity
import ManagedSettings
import FamilyControls
import CoreHaptics


struct CardView: View {
    let app: AppDeviceActivity
    let disablePopover:Bool
    
    @State private var tapped = false
    @State private var showInfo = false
    
  var body: some View {
    //        ZStack {
    //            RoundedRectangle(cornerRadius: 25, style: .continuous)
    //                .fill(.clear)
    //                .shadow(radius: 10)
    //                .shadow(radius: 10)
    //
    //            VStack {
    //                Label(app.token)
    //                    .labelStyle(.iconOnly)
    //                    .frame(width: 24, height: 24)
    //                    .scaleEffect(3)
    //                    .padding(4)
    //                    .mask(RoundedRectangle(cornerRadius: 8, style:.continuous))
    ////                    .shadow(color:Color("shadowColor").opacity(0.7), radius:5)
    ////                    .overlay(
    ////                        RoundedRectangle(cornerRadius: 8, style:.continuous)
    ////                            .stroke(Color.borderColor, lineWidth: 2)
    ////                       )
    //
    //
    //                Text(app.displayName)
    //                .font(.subheadline)
    //                    .scaledToFill()
    //                    .minimumScaleFactor(0.2)
    //                    .lineLimit(1)
    //
    //            }
    //            .padding()
    //            .multilineTextAlignment(.center)
    //
    //        }
    Label(app.token)
      .labelStyle(.iconOnly)
      .frame(width: 24, height: 24)

//      .scaleEffect(3)
      .padding(4)
      .mask(RoundedRectangle(cornerRadius: 8, style:.continuous))
    //        .frame(width: 90, height:60)
      .padding()
      .scaleEffect(tapped ? 1.4 : 1)
      .animation(.spring(response: 0.4, dampingFraction: 0.6))
      .onTapGesture{
        var temp = UIImpactFeedbackGenerator(style:.heavy)
        temp.impactOccurred()
        if !disablePopover{
          tapped.toggle()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tapped.toggle()
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
            showInfo.toggle()
          }
        }
      }
    //        .popover(isPresented: $showInfo, arrowEdge: .bottom) {
    //            CardViewPopup(app:app)
    //        }
  }
}
