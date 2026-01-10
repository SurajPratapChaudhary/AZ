import SwiftUI

struct StudioView: View {
//    @StateObject private var apiClient = SimulatedAPIClient() // Quick fix, should use real APIClient but for UI structure placeholder is fine
    // Or just simple list
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Studio")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                
                Spacer()
                
                ContentUnavailableView("No Projects Yet", systemImage: "photo.stack", description: Text("Your generated photos and reels will appear here."))
                
                Spacer()
            }
        }
    }
}
