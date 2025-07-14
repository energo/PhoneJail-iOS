import SwiftUI

extension Color {
  static let as_green = Color(hex: "24F38F")
  static let as_red = Color(hex: "FF3D3D")
  static let as_gray = Color(hex: "CACACA")
  static let as_blue_toggle = Color(hex: "1D4CD9")
  static let as_hyper_link = Color(hex: "6D86FF")
  static let as_white_light = Color(hex: "CFD3E6")
  
  //MARK: - Other Colors
  static let ri_gray = Color(red: 138/255, green: 138/255, blue: 139/255)
  static let ri_blue = Color(red: 179/255, green: 86/255, blue: 255/255)
  static let ri_black = Color(hex: "151515")
  static let ri_black_gray = Color(hex: "3B3B3B")
  static let ri_blue_gray = Color(hex: "005FDB")
  static let ri_pink = Color(hex: "FF2F63")
  static let ri_orange = Color(hex: "FFAE2C")

  static let ri_blue_stats = Color(hex: "5500FF")
//  static let ri_purple_stats = Color(hex: "9D36D8")
  static let ri_orange_stats = Color(hex: "FB7E01")
  
  static let ri_progress_active = Color(hex: "0D0CD6")
  static let ri_progress_not_active = Color(hex: "AEAEAE").opacity(0.5)
  static let ri_white_gray = Color(hex: "EFEFEF")
  
  static let td_gray = Color(red: 107/255, green: 107/255, blue: 107/255)
  static let td_red = Color(red: 255/255, green: 0/255, blue: 0/255)
  static let td_pink = Color(red: 230/255, green: 2/255, blue: 244/255)
  static let td_purple = Color(red: 109/255, green: 65/255, blue: 206/255)
  static let td_purple_dark = Color(red: 121/255, green: 9/255, blue: 128/255)
  static let td_pinch = Color(red: 255/255, green: 142/255, blue: 134/255)

  static let td_pink_start = Color(red: 251/255, green: 0/255, blue: 255/255)
  static let td_orange_end = Color(red: 255/255, green: 157/255, blue: 0/255)

  static let td_step_bg = Color(red: 19/255, green: 0/255, blue: 67/255)
  static let td_step_progress_txt = Color(red: 50/255, green: 2/255, blue: 115/255)
  static let td_step_stroke = Color(red: 216/255, green: 16/255, blue: 229/255)

  static let td_habit_time = Color(red: 255/255, green: 122/255, blue: 210/255)
  static let td_habit_day = Color(red: 241/255, green: 50/255, blue: 161/255)

  static let td_row_bg = Color(red: 98/255, green: 79/255, blue: 187/255).opacity(0.2)
  
  static let td_row_bg_nc_start = Color(red: 131/255, green: 33/255, blue: 216/255, opacity: 0.5)
  static let td_row_bg_nc_end = Color(red: 131/255, green: 33/255, blue: 216/255, opacity: 0.5)

  static let td_row_bg_c_start = Color(red: 19/255, green: 0/255, blue: 67/255)
  static let td_row_bg_c_end = Color(red: 19/255, green: 0/255, blue: 67/255)

  static let td_row_bg1_start = Color(red: 72/255, green: 126/255, blue: 233/255)
  static let td_row_bg1_end = Color(red: 219/255, green: 36/255, blue: 36/255)
  
  static let td_row_bg2_start = Color(red: 109/255, green: 65/255, blue: 206/255).opacity(0.7)
  static let td_row_bg2_end = Color(red: 141/255, green: 32/255, blue: 194/255).opacity(0.7)
  
  static let td_segment_start = Color(red: 109/255, green: 65/255, blue: 206/255).opacity(0.7)
  static let td_segment_end = Color(red: 141/255, green: 32/255, blue: 194/255).opacity(0.7)
  
  static let td_row_bg_un_start = Color(red: 98/255, green: 79/255, blue: 187/255)
  static let td_row_bg_un_end = Color(red: 32/255, green: 15/255, blue: 59/255)

  static let td_sheet_bg_start = Color(red: 98/255, green: 79/255, blue: 187/255)
  static let td_sheet_bg_end = Color(red: 64/255, green: 18/255, blue: 137/255)

  static let td_sheet_txt_start = Color(red: 98/255, green: 79/255, blue: 187/255)
  static let td_sheet_txt_end = Color(red: 32/255, green: 15/255, blue: 59/255)

  static let td_row_bg_checked = Color(red: 73/255, green: 13/255, blue: 126/255).opacity(0.2)
  
  static let td_gradient_black_start = Color(red: 17/255, green: 14/255, blue: 35/255)
  static let td_gradient_black_end = Color(red: 10/255, green: 10/255, blue: 12/255)
  
  static let td_black_stroke = Color(red: 65/255, green: 61/255, blue: 87/255)

  static let td_gradient_progress_start = Color(red: 217/255, green: 39/255, blue: 250/255)
  static let td_gradient_progress_end = Color(red: 116/255, green: 1/255, blue: 237/255)
  
  static let td_button_purple_start = Color(red: 234/255, green: 0/255, blue: 238/255)
  static let td_button_purple_end = Color(red: 105/255, green: 0/255, blue: 156/255)
}

extension Color {
  static let ritualPurple = Color(hex: "#5400C1")
  static let ritualDark = Color(hex: "#1B1C1D")
}

extension Color {
  static let as_gradietn_time_text = LinearGradient(
    stops: [
      .init(color: Color(hex: "#CF4633"), location: 0.0),
      .init(color: Color(hex: "#DDB7E9"), location: 0.34),
      .init(color: Color(hex: "#C1CBFE"), location: 0.64),
      .init(color: Color(hex: "#1D4CD9"), location: 1.0)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
  
  static let as_gradietn_stroke = LinearGradient(
    colors: [Color(hex: "6468E4"),
             Color(hex: "E28180")],
    startPoint: .leading,
    endPoint: .trailing
  )
  
  static let as_gradietn_main_button = LinearGradient(
    colors: [Color(hex: "FF6061"),
             Color(hex: "3D47C4")],
    startPoint: .topTrailing,
    endPoint: .bottomLeading
  )
  
  static let as_gradietn_main_red_button = LinearGradient(
    colors: [Color(hex: "FF3D3D"),
             Color(hex: "880808")],
    startPoint: .topTrailing,
    endPoint: .bottomLeading
  )
  
  static let as_gradietn_button_purchase = LinearGradient(
    colors: [Color(hex: "FF6061"),
             Color(hex: "3D47C4")],
    startPoint: .bottomLeading,
    endPoint: .topTrailing
  )

  //MARK: - Other Gradients
  static let gradient_simple_bg = RadialGradient(
    gradient: Gradient(colors: [Color(hex: "#3B3838"),
                                Color(hex: "#212540")]),
    center: .topLeading,
    startRadius: 5,
    endRadius: 200
  )
  
  static let gradient_sheet_bg = RadialGradient(
    gradient: Gradient(colors: [Color(hex: "#5400C1"), Color(hex: "#1B1C1D")]),
    center: UnitPoint(x: 0.96, y: 0.4), // ⬅️ Сдвиг вправо и вверх
    startRadius: 5,
    endRadius: 300
  )
  
  static let gradient_sheet_txt = LinearGradient(
    colors: [.td_sheet_txt_start.opacity(0.7),
             .td_sheet_txt_end.opacity(0.7)],
    startPoint: .top,
    endPoint: .bottom
  )
  
  static let gradient_button_action = LinearGradient(
    colors: [.td_button_purple_start,
             .td_button_purple_end],
    startPoint: .top,
    endPoint: .bottom
  )
  
  static let gradient_button_premium = LinearGradient(
//    colors: [.ri_blue_gray,
//             .td_pink_start,
//             .td_orange_end],
    colors: [.ri_blue_gray,
             .ri_pink,
             .ri_orange],
    startPoint: .leading,
    endPoint: .trailing
  )

  static let gradient_segment_active = LinearGradient(
    colors: [.td_segment_start,
             .td_segment_end],
    startPoint: .top,
    endPoint: .bottom
  )
  
  static let gradient_bg_not_active = LinearGradient(
    colors: [.td_row_bg_un_start,
             .td_row_bg_un_end],
    startPoint: .top,
    endPoint: .bottom
  )
  
  static let gradient_bg_active = LinearGradient(
    colors: [.td_row_bg1_start,
             .td_row_bg1_end],
    startPoint: .center,
    endPoint: .bottom
  )
  
  static let gradient_habit_card_bg = LinearGradient(
    colors: [.td_sheet_bg_start.opacity(0.35),
             .td_sheet_bg_end.opacity(0.35)],
    startPoint: .leading,
    endPoint: .trailing
  )
  
  static let gradient_purple = LinearGradient(
    gradient: Gradient(colors: [.td_gradient_progress_start,
                                .td_gradient_progress_end]),
    startPoint: .top,
    endPoint: .bottom
    )
  
  static let gradient_black = LinearGradient(
    colors: [.td_gradient_black_start, .td_gradient_black_end],
    startPoint: .top,
    endPoint: .bottom
  )
  
  static let gradient_todo_bg_nc = LinearGradient(
    colors: [.td_row_bg_nc_start, .td_row_bg_nc_end],
    startPoint: .leading,
    endPoint: .trailing
  )
  
  static let gradient_todo_bg_c = LinearGradient(
    colors: [.td_row_bg_c_start, .td_row_bg_c_end],
    startPoint: .leading,
    endPoint: .trailing
  )
  
  static let gradient_rainbow = LinearGradient(
      gradient: Gradient(colors: [
          Color(hex: "#FFF500"),
          Color(hex: "#F11CA4"),
          Color(hex: "#7A0CFC"),
          Color(hex: "#EE0D1E")
      ]),
      startPoint: .leading,
      endPoint: .trailing
  )

  static let radial_white = RadialGradient(
    gradient: Gradient(colors: [Color.white.opacity(0.8)]),
    center: .center,
    startRadius: 20,
    endRadius: 200
  )
  
  static let gradient_bg_cell_completed = LinearGradient(
      gradient: Gradient(colors: [Color(hex: "#5A6077"),
                                  Color(hex: "#2A39E0")]),
      startPoint: .leading,
      endPoint: .trailing
  )
  
  static let gradient_bg_cell_active = RadialGradient(
      gradient: Gradient(colors: [
          Color(hex: "#3D44BF").opacity(0.7), // Первый радиальный цвет с 70% прозрачности
          Color(hex: "#0900FF").opacity(0.83)  // Второй радиальный цвет с 83% прозрачности
      ]),
      center: .center,
      startRadius: 20,
      endRadius: 200
  )
  
  static let gradient_bg_white = LinearGradient(
    gradient: Gradient(colors: [
      Color(hex: "#B78CFA"), //
      Color(hex: "#FFFFFF")  //
    ]),
    startPoint: .top,
    endPoint: .bottom
  )
  
  static let gradient_bg_cell_not_active = LinearGradient(
    gradient: Gradient(colors: [
        Color(hex: "#1A2A44"), // темный синий
        Color(hex: "#0F1A2A")  // еще более темный синий
    ]),
    startPoint: .topLeading,  // Начало градиента
    endPoint: .bottomTrailing // Конец градиента
)

  static let radial_bg_play_button = RadialGradient(
      gradient: Gradient(colors: [
          Color(hex: "#8D40CB").opacity(0.28),  // Начальный цвет с 28% прозрачностью
          Color(hex: "#8D40CB")  // Конечный цвет с полной насыщенностью
      ]),
      center: .center,
      startRadius: 0,
      endRadius: 50
  )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (без альфы)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
