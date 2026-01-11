//
//  StyleSelectorPill.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct StyleSelectorPill: View {
    @Binding var selected: AuraStyle

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AuraStyle.allCases) { style in
                    Button {
                        selected = style
                    } label: {
                        Text(style.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected == style ? Color(hex: "01A67C") : Color.white.opacity(0.10))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        StyleSelectorPill(selected: .constant(.luxury))
    }
}
