//
//  GuidanceBadge.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct GuidanceBadge: View {
    let state: GuidanceService.State

    var text: String {
        switch state {
        case .good: return "Good"
        case .lowLight: return "More light"
        case .unstable: return "Hold steady"
        case .adjustPosition: return "Center yourself"
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.45))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .allowsHitTesting(false)
    }
}
