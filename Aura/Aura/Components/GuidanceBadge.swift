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

    var icon: String? {
        switch state {
        case .good: return nil
        case .lowLight: return "sun.min.fill"
        case .unstable: return "hand.raised.fill"
        case .adjustPosition: return "person.fill.viewfinder"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .allowsHitTesting(false)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
        // Hidden when good to minimize clutter or show minimal "Ready" state? 
        // PRD says "Minimal guidance". Let's show nothing if good, or a subtle "Ready".
        // Current impl shows "Good". Let's hide if Good to be "Apple-like" (only show warnings)
        // UNLESS the user wants to know it's working.
        // Re-reading PRD 4.3: Allowed Hints: "Stay in frame", "Step back", "More light", "Hold steady".
        // It does NOT list "Good". So we should hide if good.
        .opacity(state == .good ? 0.0 : 1.0)
    }
}
