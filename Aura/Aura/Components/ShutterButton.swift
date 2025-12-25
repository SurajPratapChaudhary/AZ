//
//  ShutterButton.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct ShutterButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(.white.opacity(0.20)).frame(width: 78, height: 78)
                Circle().stroke(.white, lineWidth: 3).frame(width: 66, height: 66)
            }
        }
        .buttonStyle(.plain)
    }
}
