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
    
    @StateObject private var permissionManager = PermissionManager()
    @State private var showSplash = true
    @State private var isCheckedPermissions = false
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                Group {
                    if authToken == nil || authToken?.isEmpty == true {
                         AuthView()
                    } else {
                         if permissionManager.camera == .authorized && permissionManager.photos == .authorized {
                             TabbarView()
                         } else {
                             PermissionGateView(onComplete: {
                                 Task { await permissionManager.refresh() }
                             })
                         }
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            await permissionManager.refresh()
            isCheckedPermissions = true
            
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation {
                showSplash = false
            }
        }
    }
    
    private var hasAllPermissions: Bool {
        return permissionManager.camera == .authorized &&
               permissionManager.photos == .authorized &&
               (permissionManager.notifications == .authorized || permissionManager.notifications == .denied) 
    }
}

#Preview {
    ContentView()
}
