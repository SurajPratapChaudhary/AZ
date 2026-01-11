
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showDefaultStyle = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "020202").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    Text("Profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Credits Cell
                            ProfileMenuCell(
                                icon: "banknote",
                                title: "Credits remaining",
                                value: "\(viewModel.credits)",
                                showChevron: false
                            )
                            
                            // Buy Credits
                            NavigationLink {
                                BuyCreditsView()
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                ProfileMenuCell(
                                    icon: "creditcard",
                                    title: "Buy Credits",
                                    showChevron: true
                                )
                            }
                            
                            // Default Style
                            Button {
                                showDefaultStyle = true
                            } label: {
                                ProfileMenuCell(
                                    icon: "sparkles",
                                    title: "Default Style",
                                    value: viewModel.defaultStyle.rawValue.capitalized,
                                    showChevron: true
                                )
                            }
                            
                            // Restore Purchases
                            Button {
                                // Restore action
                            } label: {
                                ProfileMenuCell(
                                    icon: "arrow.clockwise",
                                    title: "Restore Purchases",
                                    showChevron: true
                                )
                            }
                            
                            // Terms & Policy
                            Link(destination: URL(string: "https://aura.zbekz.com/terms")!) {
                                ProfileMenuCell(
                                    icon: "doc.text",
                                    title: "Terms & Policy",
                                    showChevron: true
                                )
                            }
                            
                            // Support
                            Button {
                                // Support action
                            } label: {
                                ProfileMenuCell(
                                    icon: "headphones",
                                    title: "Control Support",
                                    showChevron: true
                                )
                            }
                            
                            // Logout
                            Button {
                                UserDefaults.standard.set(nil, forKey: "aura.authToken")
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.red.opacity(0.8))
                                        .frame(width: 24)
                                    
                                    Text("Log Out")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.red)
                                    
                                    Spacer()
                                }
                                .padding(20)
                                .background(Color(hex: "121214"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchCredits()
                }
            }
            .sheet(isPresented: $showDefaultStyle) {
                DefaultStyleSelectionView(viewModel: viewModel)
            }
        }
    }
}

struct ProfileMenuCell: View {
    let icon: String
    let title: String
    var value: String? = nil
    let showChevron: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(20)
        .background(Color(hex: "121214"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
}
