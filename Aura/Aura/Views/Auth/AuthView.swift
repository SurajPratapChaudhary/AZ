import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var authService = AuthService(apiClient: APIClient())
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("Shoot. We upgrade the scene.")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .minimumScaleFactor(0.8)
                
                Text("No filters. No retouching. Just premium results.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                AppleButton()
                
                GoogleButton()
                
                EmailButton()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .alert("Something went wrong",
               isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.errorMessage = nil
                    }
                }
               ),
               presenting: viewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: { error in
            Text(error)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Image("auth-background-image")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.4))
        }
    }
    
    @ViewBuilder func EmailButton() -> some View {
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
    
    @ViewBuilder func GoogleButton() -> some View {
        Button {
            handleGoogleSignIn()
        } label: {
            HStack(spacing: 12) {
                Image("google-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("Continue with Google")
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
    
    @ViewBuilder func AppleButton() -> some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            viewModel.handleAppleLogin(result, authService: authService)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 28))
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
