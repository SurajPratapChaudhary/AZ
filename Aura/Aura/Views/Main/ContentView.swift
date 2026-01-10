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
    
    // We can use the PermissionManager here to decide whether to show Gate or Main
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
                         // User not logged in, show Auth (which is the Onboarding V1)
                         AuthView()
                    } else {
                         // User is logged in. Check Permissions.
                         // We require Camera and Photos strictly. Notifications we can be lenient or strict.
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
            // Start background checks immediately
            await permissionManager.refresh()
            isCheckedPermissions = true
            
            // Wait for splash
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s
            withAnimation {
                showSplash = false
            }
        }
    }
    
    private var hasAllPermissions: Bool {
        return permissionManager.camera == .authorized &&
               permissionManager.photos == .authorized &&
               (permissionManager.notifications == .authorized || permissionManager.notifications == .denied) // If denied we might proceed if "recommended"? 
               // User said "if not permission granted you open that view". strictly.
               // So let's require .authorized for Camera/Photos at least.
    }
}

#Preview {
    ContentView()
}
