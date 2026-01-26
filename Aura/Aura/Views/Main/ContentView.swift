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
            let startTime = Date()
            
            async let permissionsTask: () = permissionManager.refresh()
            async let validationTask: Bool = validateSessionIfNeeded()
            
            await permissionsTask
            let isValid = await validationTask
            
            if !isValid {
                authToken = nil
            }
            
            isCheckedPermissions = true
            
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumSplashTime: TimeInterval = 2.0
            if elapsed < minimumSplashTime {
                try? await Task.sleep(nanoseconds: UInt64((minimumSplashTime - elapsed) * 1_000_000_000))
            }
            
            withAnimation {
                showSplash = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
            authToken = nil
        }
    }
    
    private func validateSessionIfNeeded() async -> Bool {
        guard SessionManager.shared.hasValidSession else { return true }
        return await SessionManager.shared.validateSession()
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
