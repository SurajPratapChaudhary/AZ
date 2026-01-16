
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
        if let token = defaults.string(forKey: "aura.authToken"), !token.isEmpty {
            self.isAuthenticated = true
            self.userId = defaults.string(forKey: "aura.userId")
        } else {
            self.isAuthenticated = false
        }
    }
    
    func login(token: String, provider: String = "apple") async throws {
        do {
            let response = try await apiClient.login(token: token, provider: provider)
            // Save session
            defaults.set(response.access_token, forKey: "aura.authToken")
            defaults.set(response.user.id, forKey: "aura.userId")
            defaults.set(response.user.email, forKey: "aura.userEmail")
            defaults.set(response.user.credits, forKey: "aura.userCredits")
            
            self.isAuthenticated = true
        } catch {
            print("Auth Service Login Error: \(error)")
            throw error
        }
    }
    
    func signOut() {
        defaults.removeObject(forKey: "aura.authToken")
        defaults.removeObject(forKey: "aura.userId")
        self.isAuthenticated = false
    }
}
