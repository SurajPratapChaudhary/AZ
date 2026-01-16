
import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var credits: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var defaultStyle: AuraStyle = .luxury
    
    private let apiClient: APIClientProtocol
    private let defaults = UserDefaults.standard
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
        self.loadDefaultStyle()
    }
    
    func loadDefaultStyle() {
        if let savedStyle = defaults.string(forKey: "aura.defaultStyle"),
           let style = AuraStyle(rawValue: savedStyle) {
            self.defaultStyle = style
        }
    }
    
    func setDefaultStyle(_ style: AuraStyle) {
        self.defaultStyle = style
        defaults.set(style.rawValue, forKey: "aura.defaultStyle")
    }
    
    func fetchCredits() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getCredits()
            self.credits = response.credits
            // Update shared defaults if needed
            defaults.set(response.credits, forKey: "aura.userCredits")
        } catch {
            print("Profile fetch error: \(error)")
            // Fallback to cached if available
            self.credits = defaults.integer(forKey: "aura.userCredits")
            // self.errorMessage = "Failed to load credits" // Optional: don't show error for background fetch
        }
        
        isLoading = false
    }
}
