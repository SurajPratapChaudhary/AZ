//
//  RootView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct RootView: View {
    @AppStorage("aura.didOnboard") private var didOnboard = false

    var body: some View {
        if didOnboard {
            CameraFlowView()
        } else {
            OnboardingView()
        }
    }
}
