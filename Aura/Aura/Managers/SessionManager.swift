//
//  SessionManager.swift
//  Aura
//

import Foundation

extension Notification.Name {
    static let sessionExpired = Notification.Name("aura.sessionExpired")
}

final class SessionManager {
    static let shared = SessionManager()
    
    private let defaults = UserDefaults.standard
    private let apiClient = APIClient()
    
    static let authTokenKey = "aura.authToken"
    static let refreshTokenKey = "aura.refreshToken"
    static let providerKey = "aura.authProvider"
    
    private init() {}
    
    func handleSessionExpiry() {
        Log.e("Session expired - logging out user")
        logout()
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }
    
    func logout() {
        defaults.removeObject(forKey: Self.authTokenKey)
        defaults.removeObject(forKey: Self.refreshTokenKey)
        defaults.removeObject(forKey: Self.providerKey)
        defaults.removeObject(forKey: "aura.userId")
        defaults.removeObject(forKey: "aura.userEmail")
        defaults.removeObject(forKey: "aura.userCredits")
    }
    
    var hasValidSession: Bool {
        guard let token = defaults.string(forKey: Self.authTokenKey), !token.isEmpty else {
            return false
        }
        return true
    }
    
    var refreshToken: String? {
        return defaults.string(forKey: Self.refreshTokenKey)
    }
    
    func saveRefreshToken(_ token: String, provider: String) {
        defaults.set(token, forKey: Self.refreshTokenKey)
        defaults.set(provider, forKey: Self.providerKey)
    }
    
    func saveAccessToken(_ token: String) {
        defaults.set(token, forKey: Self.authTokenKey)
    }
    
    /// Validates the current session by calling /api/v1/user.
    /// If expired (401), attempts to refresh the token.
    /// Returns true if session is valid or successfully refreshed, false otherwise.
    @MainActor
    func validateSession() async -> Bool {
        guard hasValidSession else { return false }
        
        do {
            let _ = try await apiClient.getUser()
            return true
        } catch let error as APIError {
            if case .sessionExpired = error {
                return await attemptTokenRefresh()
            }
            return true
        } catch {
            return true
        }
    }
    
    @MainActor
    private func attemptTokenRefresh() async -> Bool {
        guard let storedRefreshToken = refreshToken else {
            Log.e("No refresh token available")
            handleSessionExpiry()
            return false
        }
        
        do {
            let response = try await apiClient.refreshToken(refreshToken: storedRefreshToken)
            let newAccessToken = response.access_token
            
            if newAccessToken.isEmpty {
                Log.e("Refresh returned empty access token")
                handleSessionExpiry()
                return false
            }
            
            saveAccessToken(newAccessToken)
            Log.d("Token refreshed successfully")
            return true
        } catch {
            Log.e("Token refresh failed: \(error)")
            handleSessionExpiry()
            return false
        }
    }
}
