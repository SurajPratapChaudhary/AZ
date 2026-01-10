
import SwiftUI

struct ProcessingView: View {
    let image: UIImage
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Blurred Background
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .blur(radius: 30) // Darker/Stronger blur
                .overlay(Color.black.opacity(0.4)) // Darken/Tint
            
            // Text Content - Bottom Aligned
            VStack(spacing: 8) {
                Spacer()
                
                Text("Trying a new look...")
                    .font(.system(size: 20, weight: .bold)) // Larger
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("This uses credits.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray) // Subtitle style
                
                Spacer().frame(height: 100) // Approximate bottom padding from screenshot
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
