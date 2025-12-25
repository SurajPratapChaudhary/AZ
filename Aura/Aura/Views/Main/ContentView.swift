//
//  ContentView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var container = AppContainer()
    
    var body: some View {
        RootView()
            .environmentObject(container)
    }
}

#Preview {
    ContentView()
}
