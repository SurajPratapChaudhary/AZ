
import Foundation
import Combine
import SwiftUI

@MainActor
final class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String?
    
    private let apiClient: APIClientProtocol
    private let defaults = UserDefaults.standard
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
        self.checkSession()
    }
    
    func checkSession() {
        if let token = defaults.string(forKey: SessionManager.authTokenKey), !token.isEmpty {
            self.isAuthenticated = true
            self.userId = defaults.string(forKey: "aura.userId")
        } else {
            self.isAuthenticated = false
        }
    }
    
    func login(token: String, provider: String = "apple") async throws {
        let response = try await apiClient.login(token: token, provider: provider)
        
        defaults.set(response.access_token, forKey: SessionManager.authTokenKey)
        defaults.set(response.user.id, forKey: "aura.userId")
        defaults.set(response.user.email, forKey: "aura.userEmail")
        defaults.set(response.user.credits, forKey: "aura.userCredits")
        
        // Save the refresh token from the backend response
        if !response.refresh_token.isEmpty {
            SessionManager.shared.saveRefreshToken(response.refresh_token, provider: provider)
        } else {
             // Fallback: use the input token if backend doesn't return one (shouldn't happen with new API)
             SessionManager.shared.saveRefreshToken(token, provider: provider)
        }
        
        self.isAuthenticated = true
    }
    
    func signOut() {
        SessionManager.shared.logout()
        self.isAuthenticated = false
    }
}
