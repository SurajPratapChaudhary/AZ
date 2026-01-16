
import SwiftUI

struct ProcessingView: View {
    let image: UIImage
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .blur(radius: 30)
                .overlay(Color.black.opacity(0.4))
            
            VStack(spacing: 8) {
                Spacer()
                
                Text("Trying a new look...")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("This uses credits.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                
                Spacer().frame(height: 100) 
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ProcessingView(image: UIImage(), message: "Filtering...")
}
