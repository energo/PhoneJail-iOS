//
//  RacingFontWeight.swift
//  AntiSocial
//
//  Created by D C on 24.06.2025.
//

import Foundation
import SwiftUI

extension UIFont {

    var monospacedDigitFont: UIFont {
        let oldFontDescriptor = fontDescriptor
        let newFontDescriptor = oldFontDescriptor.monospacedDigitFontDescriptor
        return UIFont(descriptor: newFontDescriptor, size: 0)
    }

}

private extension UIFontDescriptor {

    var monospacedDigitFontDescriptor: UIFontDescriptor {
        let fontDescriptorFeatureSettings = [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType, UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings]
        let fontDescriptor = self.addingAttributes(fontDescriptorAttributes)
        return fontDescriptor
    }
}

extension Font {
  enum FontWeight {
    case bold, regular, semibold
    
    var fontName: String {
      switch self {
        case .bold: return "ZCOOLQingKeHuangYou-Regular"
        case .semibold: return "ZCOOLQingKeHuangYou-Regular"
        case .regular: return "ZCOOLQingKeHuangYou-Regular"
      }
    }
  }
  
  enum FontSize {
    case small, smallMinus, smallPlus, middle, big, extraBig, shopItemSubTitle, shopItemTitle, lightRegular
    
    func getFontSize(for category: ScreenSizeCategory) -> CGFloat {
      switch self {
        case .small:
          return category.size(small: 14, normal: 16, big: 18)
        case .smallMinus:
          return category.size(small: 12, normal: 14, big: 14)
        case .smallPlus:
          return category.size(small: 16, normal: 18, big: 20)
        case .middle:
          return category.size(small: 24, normal: 28, big: 32)
        case .big:
          return category.size(small: 36, normal: 40, big: 44)
        case .extraBig:
          return category.size(small: 40, normal: 46, big: 56)
        case .shopItemSubTitle:
          return category.size(small: 12, normal: 14, big: 16)
        case .shopItemTitle:
          return category.size(small: 16, normal: 20, big: 24)
        case .lightRegular:
          return category.size(small: 20, normal: 24, big: 28)
      }
    }
  }
  
  enum ScreenSizeCategory {
    case small, normal, big
    
    func size(small: CGFloat, normal: CGFloat, big: CGFloat) -> CGFloat {
      switch self {
        case .small: return small
        case .normal: return normal
        case .big: return big
      }
    }
  }
  
  //MARK: - Public Methods
  static let textS = Font(UIFont.systemFont(ofSize: 14, weight: .regular)) // Аналог "Ag Text S"
  static let textM = Font(UIFont.systemFont(ofSize: 16, weight: .regular)) // Аналог "Ag Text M"
  static let textL = Font(UIFont.systemFont(ofSize: 20, weight: .bold)) // Аналог "Ag Text L"

  static func primary(weight: FontWeight = .regular,
                      size: FontSize = .small) -> Font {
    let fontSize = size.getFontSize(for: getScreenSizeCategory())
    return customFont(name: weight.fontName, size: fontSize)
  }
  
  //MARK: - Private Methods
  fileprivate static func customFont(name: String, size: CGFloat) -> Font {
    guard let uiFont = UIFont(name: name, size: size) else {
      return Font.system(size: size)
    }
    return Font(uiFont).monospacedDigit()
  }
  
  static func getScreenSizeCategory() -> ScreenSizeCategory {
    switch Device.size() {
      case .screen3_5Inch, .screen4Inch, .screen4_7Inch:
        return .small
      case .screen5_5Inch, .screen5_8Inch, .screen6_1Inch, .screen6_1Inch_2:
        return .normal
      case .screen6_5Inch, .screen6_7Inch, .screen6_7Inch_2, .screen7_9Inch, .screen9_7Inch, .screen10_5Inch, .screen12_9Inch:
        return .big
      default:
        return .normal
    }
  }
}

extension UIFont {
  static func fugaOneFont(weight: Font.FontWeight, size: Font.FontSize) -> UIFont {
    let fontSize = size.getFontSize(for: Font.getScreenSizeCategory())
    return UIFont(name: weight.fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
  }
}

extension View {
  func customStroke(color: Color, width: CGFloat) -> some View {
    modifier(StrokeModifier(strokeSize: width, strokeColor: color))
  }
}

struct StrokeModifier : ViewModifier {
  private let id = UUID()
  var strokeSize: CGFloat = 1
  var strokeColor: Color = .blue
  
  func body(content: Content) -> some View {
    content
      .padding (strokeSize*2)
      .background(Rectangle()
        .foregroundStyle(strokeColor)
        .mask({
          outline(context: content)
        })
      )
  }
  
  func outline(context: Content) -> some View {
    Canvas { context, size in
      context.addFilter(.alphaThreshold(min: 0.01))
      context.drawLayer { layer in
        if let text = context.resolveSymbol(id: id) {
          layer.draw(text,at: .init(x: size.width/2, y: size.height/2))
        }
      }
    } symbols: {
      context.tag(id)
        .blur(radius: strokeSize)
    }
  }
}
