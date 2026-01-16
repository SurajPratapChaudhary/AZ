//
//  SafeFrameOverlay.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct SafeFrameOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            // Insets based on Figma visual estimate
            // Top is below the header (approx 80-100pt down?)
            // Bottom is above the shutter (approx 150-180pt up?)
            // Side padding approx 20pt
            
            let sidePadding: CGFloat = 24
            let topPadding: CGFloat = 110 // Below top bar
            let bottomPadding: CGFloat = 180 // Above shutter area
            
            let cornerLength: CGFloat = 40
            let lineWidth: CGFloat = 1
            
            Path { path in
                // Top Left
                path.move(to: CGPoint(x: sidePadding, y: topPadding + cornerLength))
                path.addLine(to: CGPoint(x: sidePadding, y: topPadding))
                path.addLine(to: CGPoint(x: sidePadding + cornerLength, y: topPadding))
                
                // Top Right
                path.move(to: CGPoint(x: w - sidePadding - cornerLength, y: topPadding))
                path.addLine(to: CGPoint(x: w - sidePadding, y: topPadding))
                path.addLine(to: CGPoint(x: w - sidePadding, y: topPadding + cornerLength))
                
                // Bottom Left
                path.move(to: CGPoint(x: sidePadding, y: h - bottomPadding - cornerLength))
                path.addLine(to: CGPoint(x: sidePadding, y: h - bottomPadding))
                path.addLine(to: CGPoint(x: sidePadding + cornerLength, y: h - bottomPadding))
                
                // Bottom Right
                path.move(to: CGPoint(x: w - sidePadding - cornerLength, y: h - bottomPadding))
                path.addLine(to: CGPoint(x: w - sidePadding, y: h - bottomPadding))
                path.addLine(to: CGPoint(x: w - sidePadding, y: h - bottomPadding - cornerLength))
            }
            .stroke(Color.white.opacity(0.5), lineWidth: lineWidth)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(.all, edges: .all) // Use GeometryReader full bounds, frame logic handles inset
    }
}

#Preview {
    ZStack {
        Color.black
        SafeFrameOverlay()
    }
}
