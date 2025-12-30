//
//  ContentView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("aura.didOnboard") private var didOnboard = false
    @AppStorage("aura.authToken") private var authToken: String?
    
    var body: some View {
        Group {
            if !didOnboard {
                OnboardingView()
            } else if authToken == nil || authToken?.isEmpty == true {
                AuthView()
            } else {
                CameraFlowView()
            }
        }
    }
}

#Preview {
    ContentView()
}
