import SwiftUI

struct TabbarView: View {
    @State private var selectedTab: Int = 1 // Start on Camera (Index 1)
    
    init() {
        // Customizing TabBar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            StudioView()
                .tabItem {
                    Image(systemName: "video")
                    Text("Studio")
                }
                .tag(0)
            
            CameraFlowView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(2)
        }
        .tint(Color("AccentColor"))
        .environment(\.symbolVariants, .none) // Force outline even when selected
    }
}
