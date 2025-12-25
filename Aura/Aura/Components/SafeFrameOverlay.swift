//
//  SafeFrameOverlay.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct SafeFrameOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(.white.opacity(0.35), lineWidth: 2)
            .padding(.horizontal, 56)
            .padding(.top, 90)
            .padding(.bottom, 190)
            .allowsHitTesting(false)
    }
}
