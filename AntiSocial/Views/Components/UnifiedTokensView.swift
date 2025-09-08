//
//  UnifiedTokensView.swift
//  AntiSocial
//
//  Created by Claude on 08.09.2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings

/// Универсальный компонент для отображения токенов разных типов
/// Поддерживает ApplicationToken, ActivityCategoryToken и WebDomainToken
struct UnifiedTokensView: View {
    // MARK: - Properties
    
    /// Семейство токенов для отображения
    let familyActivitySelection: FamilyActivitySelection
    
    /// Максимальное количество иконок для отображения
    var maxIcons: Int = 4
    
    /// Размер иконок
    var iconSize: CGFloat = 20
    
    /// Перекрытие иконок
    var overlap: CGFloat = -8
    
    /// Показывать ли счетчик
    var showCount: Bool = true
    
    /// Шрифт для счетчика
    var countFont: Font = .system(size: 14, weight: .regular)
    
    /// Цвет счетчика
    var countColor: Color = Color.as_white_light
    
    /// Расстояние между элементами
    var spacing: CGFloat = 4
    
    /// Показывать ли только определенные типы токенов
    var tokenTypes: Set<TokenType> = [.applications, .categories, .webDomains]
    
    // MARK: - Token Types
    
    enum TokenType: CaseIterable {
        case applications
        case categories
        case webDomains
        
        var displayName: String {
            switch self {
            case .applications: return "Apps"
            case .categories: return "Categories"
            case .webDomains: return "Websites"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Общее количество токенов всех типов
    private var totalTokenCount: Int {
        var count = 0
        if tokenTypes.contains(.applications) {
            count += familyActivitySelection.applicationTokens.count
        }
        if tokenTypes.contains(.categories) {
            count += familyActivitySelection.categoryTokens.count
        }
        if tokenTypes.contains(.webDomains) {
            count += familyActivitySelection.webDomainTokens.count
        }
        return count
    }
    
    /// Все токены для отображения (только иконки)
    private var allTokensForDisplay: [AnyToken] {
        var tokens: [AnyToken] = []
        
        if tokenTypes.contains(.applications) {
            tokens.append(contentsOf: familyActivitySelection.applicationTokens.map { AnyToken.application($0) })
        }
        if tokenTypes.contains(.categories) {
            tokens.append(contentsOf: familyActivitySelection.categoryTokens.map { AnyToken.category($0) })
        }
        if tokenTypes.contains(.webDomains) {
            tokens.append(contentsOf: familyActivitySelection.webDomainTokens.map { AnyToken.webDomain($0) })
        }
        
        return Array(tokens.prefix(maxIcons))
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: spacing) {
            if showCount {
                Text("\(totalTokenCount)")
                    .font(countFont)
                    .foregroundStyle(countColor)
            }
            
            if !allTokensForDisplay.isEmpty {
                stackedIcons
            }
        }
    }
    
    // MARK: - Stacked Icons
    
    private var stackedIcons: some View {
        HStack(spacing: overlap) {
            ForEach(allTokensForDisplay.indices, id: \.self) { index in
                let token = allTokensForDisplay[index]
                tokenIcon(for: token)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .zIndex(Double(index)) // Right icon on top
            }
        }
    }
    
    // MARK: - Token Icon
    
    @ViewBuilder
    private func tokenIcon(for token: AnyToken) -> some View {
        switch token {
        case .application(let appToken):
            Label(appToken)
                .labelStyle(.iconOnly)
                .background(Color.white)
        case .category(let categoryToken):
            Label(categoryToken)
                .labelStyle(.iconOnly)
                .background(Color.white)
        case .webDomain(let webToken):
            webDomainIcon(for: webToken)
        }
    }
    
    // MARK: - Web Domain Icon
    
    @ViewBuilder
    private func webDomainIcon(for webToken: WebDomainToken) -> some View {
        // Для WebDomainToken используем системную иконку глобуса
        Image(systemName: "globe")
            .foregroundColor(.white)
            .background(Color.blue)
    }
}

// MARK: - AnyToken Wrapper

/// Обертка для унификации разных типов токенов
enum AnyToken: Identifiable {
    case application(ApplicationToken)
    case category(ActivityCategoryToken)
    case webDomain(WebDomainToken)
    
    var id: String {
        switch self {
        case .application(let token):
            return "app_\(String(describing: token))"
        case .category(let token):
            return "cat_\(String(describing: token))"
        case .webDomain(let token):
            return "web_\(String(describing: token))"
        }
    }
}

// MARK: - Convenience Initializers

extension UnifiedTokensView {
    /// Инициализатор только для приложений
    init(applicationTokens: Set<ApplicationToken>,
         maxIcons: Int = 4,
         iconSize: CGFloat = 20,
         overlap: CGFloat = -8,
         showCount: Bool = true,
         countFont: Font = .system(size: 14, weight: .regular),
         countColor: Color = Color.as_white_light,
         spacing: CGFloat = 4) {
        var selection = FamilyActivitySelection()
        selection.applicationTokens = applicationTokens
        self.familyActivitySelection = selection
        self.maxIcons = maxIcons
        self.iconSize = iconSize
        self.overlap = overlap
        self.showCount = showCount
        self.countFont = countFont
        self.countColor = countColor
        self.spacing = spacing
        self.tokenTypes = [.applications]
    }
    
    /// Инициализатор только для категорий
    init(categoryTokens: Set<ActivityCategoryToken>,
         maxIcons: Int = 4,
         iconSize: CGFloat = 20,
         overlap: CGFloat = -8,
         showCount: Bool = true,
         countFont: Font = .system(size: 14, weight: .regular),
         countColor: Color = Color.as_white_light,
         spacing: CGFloat = 4) {
        var selection = FamilyActivitySelection()
        selection.categoryTokens = categoryTokens
        self.familyActivitySelection = selection
        self.maxIcons = maxIcons
        self.iconSize = iconSize
        self.overlap = overlap
        self.showCount = showCount
        self.countFont = countFont
        self.countColor = countColor
        self.spacing = spacing
        self.tokenTypes = [.categories]
    }
    
    /// Инициализатор только для веб-доменов
    init(webDomainTokens: Set<WebDomainToken>,
         maxIcons: Int = 4,
         iconSize: CGFloat = 20,
         overlap: CGFloat = -8,
         showCount: Bool = true,
         countFont: Font = .system(size: 14, weight: .regular),
         countColor: Color = Color.as_white_light,
         spacing: CGFloat = 4) {
        var selection = FamilyActivitySelection()
        selection.webDomainTokens = webDomainTokens
        self.familyActivitySelection = selection
        self.maxIcons = maxIcons
        self.iconSize = iconSize
        self.overlap = overlap
        self.showCount = showCount
        self.countFont = countFont
        self.countColor = countColor
        self.spacing = spacing
        self.tokenTypes = [.webDomains]
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Пример с пустым FamilyActivitySelection
        UnifiedTokensView(familyActivitySelection: FamilyActivitySelection())
        
        // Пример с кастомными настройками
        UnifiedTokensView(
            familyActivitySelection: FamilyActivitySelection(),
            iconSize: 24,
            overlap: -10,
            showCount: false
        )
        
        // Пример только с приложениями
        UnifiedTokensView(applicationTokens: [])
        
        // Пример только с категориями
        UnifiedTokensView(categoryTokens: [])
        
        // Пример только с веб-доменами
        UnifiedTokensView(webDomainTokens: [])
    }
    .padding()
    .background(Color.black)
}
