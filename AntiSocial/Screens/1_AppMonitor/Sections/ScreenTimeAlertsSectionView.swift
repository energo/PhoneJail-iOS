//
//  ScreenTimeAlertsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct ScreenTimeAlertsSectionView: View {
    @Binding var selectedAlertCategories: [AlertCategory]
    @Binding var notifyInterval: TimeInterval
    @Binding var isAlertEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screentime Alerts")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    Button(action: { toggleCategory(category) }) {
                        Text(category.title)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedAlertCategories.contains(category) ? Color.accentColor : Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                }
            }
            HStack {
                Text("Notify Me Every")
                Spacer()
                Picker("", selection: $notifyInterval) {
                    ForEach([10, 20, 30, 60], id: \.self) { value in
                        Text("\(value) Mins").tag(TimeInterval(value * 60))
                    }
                }
                .pickerStyle(.menu)
            }
            Toggle(isOn: $isAlertEnabled) {
                EmptyView()
            }
            .toggleStyle(SwitchToggleStyle(tint: .purple))
        }
        .padding()
    }

    private func toggleCategory(_ category: AlertCategory) {
        if let idx = selectedAlertCategories.firstIndex(of: category) {
            selectedAlertCategories.remove(at: idx)
        } else {
            selectedAlertCategories.append(category)
        }
    }
}
