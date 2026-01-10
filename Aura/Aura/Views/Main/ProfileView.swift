import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Profile")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                
                Spacer()
                
                // Placeholder for credits
                VStack(spacing: 8) {
                    Text("360")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color("AccentColor"))
                    Text("Credits Available")
                        .foregroundStyle(.gray)
                }
                
                Spacer()
            }
        }
    }
}
