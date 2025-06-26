//
//  AppBlockingSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct AppBlockingSectionView: View {
    @Binding var duration: TimeInterval
    @Binding var categories: [AppCategory]
    @Binding var isStrictBlock: Bool
    var onBlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Blocking")
                .font(.headline)
            HStack {
                Text("Duration")
                Spacer()
                Picker("", selection: $duration) {
                    ForEach([0, 10, 20, 30, 40, 50, 60, 120, 180], id: \.self) { value in
                        Text("\(value / 60)h \(value % 60)m").tag(TimeInterval(value * 60))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
            }
            HStack(spacing: 8) {
                ForEach(AppCategory.allCases, id: \.self) { category in
                    Button(action: { toggleCategory(category) }) {
                        Text(category.title)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(categories.contains(category) ? Color.accentColor : Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                }
            }
            Toggle("Strict Block", isOn: $isStrictBlock)
            Button(action: onBlock) {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("Swipe to Block")
                }
                .padding()
                .background(Color.as_gradietn_time_text)
                .cornerRadius(16)
            }
        }
        .padding()
    }

    private func toggleCategory(_ category: AppCategory) {
        if let idx = categories.firstIndex(of: category) {
            categories.remove(at: idx)
        } else {
            categories.append(category)
        }
    }
}
