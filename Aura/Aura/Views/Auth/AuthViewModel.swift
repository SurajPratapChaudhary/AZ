
import SwiftUI
import Combine
import AuthenticationServices
import GoogleSignIn

@MainActor
class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    func handleAppleLogin(_ result: Result<ASAuthorization, Error>, authService: AuthService) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid credential type."
                return
            }
            
            let idToken = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            let authCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
             
            print("DEBUG: Apple Sign In Success")
            print("ID Token: \(idToken ?? "nil")")
            print("Auth Code: \(authCode ?? "nil")")
            
            guard let tokenToSend = idToken else {
                 errorMessage = "Could not fetch Identity Token from Apple."
                 return
            }
            
            Task {
                do {
                    try await authService.login(token: tokenToSend, provider: "apple")
                } catch {
                    errorMessage = "Login failed: \(error.localizedDescription)"
                }
            }
            
        case .failure(let error):
            print("Apple Sign-in failed: \(error.localizedDescription)")
            errorMessage = "Sign in failed. Please try again."
        }
    }
    
    func handleGoogleLogin(presentingViewController: UIViewController, authService: AuthService) {
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Google Sign-in failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self.errorMessage = "Google Sign in failed. Please try again."
                }
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                Task { @MainActor in
                    self.errorMessage = "Could not fetch Google ID Token."
                }
                return
            }
            
            print("DEBUG: Google Sign In Success")
            print("ID Token: \(idToken)")
            
            Task { @MainActor in
                do {
                    try await authService.login(token: idToken, provider: "google")
                } catch {
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
