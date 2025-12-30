
import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var authService = AuthService(apiClient: APIClient())
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("Welcome to Aura")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Sign in to continue using premium features.")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    // Apple Sign In Button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        viewModel.handleAppleLogin(result, authService: authService)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 44)
                    
                    // Google Sign In Button
                    Button {
                        handleGoogleSignIn()
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Sign in with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            viewModel.errorMessage = "Could not find root view controller"
            return
        }
        
        viewModel.handleGoogleLogin(presentingViewController: rootViewController, authService: authService)
    }
}

#Preview {
    AuthView()
}
