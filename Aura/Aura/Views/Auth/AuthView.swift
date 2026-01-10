
import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var authService = AuthService(apiClient: APIClient())
    
    var body: some View {
        ZStack {
            // Background Image
            Image("auth-background-image")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.4)) // Overlay for readability if needed
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Shoot. We upgrade the scene.")
                        .font(.system(size: 34, weight: .bold)) // Adjust size as needed
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("No filters. No retouching. Just premium results.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .padding(.bottom, 10)
                }
                
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        viewModel.handleAppleLogin(result, authService: authService)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    
                    // Google Button
                    Button {
                        handleGoogleSignIn()
                    } label: {
                        HStack {
                            Image("google-icon")
                                .font(.system(size: 20))
                            Text("Continue With Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.1))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // Email Button
                    Button {
                        // Email flow placeholder
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue With Email")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.1))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                         .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
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
