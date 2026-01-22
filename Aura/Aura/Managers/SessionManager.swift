//
//  SessionManager.swift
//  Aura
//
//  Created by Antigravity on 2026-01-19.
//

import Foundation

extension Notification.Name {
    static let sessionExpired = Notification.Name("aura.sessionExpired")
}

/// Centralized session manager for handling authentication state and session expiry.
final class SessionManager {
    static let shared = SessionManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    /// Call this when a 401 Unauthorized error is received from any API.
    /// This will clear the session and broadcast a notification for the UI to react.
    func handleSessionExpiry() {
        Log.e("Session expired - logging out user")
        logout()
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }
    
    /// Clears all authentication-related data from UserDefaults.
    func logout() {
        defaults.removeObject(forKey: "aura.authToken")
        defaults.removeObject(forKey: "aura.userId")
        defaults.removeObject(forKey: "aura.userEmail")
        defaults.removeObject(forKey: "aura.userCredits")
        Log.d("User session cleared")
    }
    
    /// Checks if the user has a valid auth token stored.
    var hasValidSession: Bool {
        guard let token = defaults.string(forKey: "aura.authToken"), !token.isEmpty else {
            return false
        }
        return true
    }
}
