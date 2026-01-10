
import SwiftUI

struct StudioImageDetailView: View {
    let item: StudioHistoryResponse.StudioItem
    var onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Image content
                // Image content
                if let urlString = item.variants.first, let url = URL(string: urlString) {
                    AuraImageView(url: url)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 500)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                } else {
                    Text("No image found")
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                // Bottom Sheet Overlay
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enhanced")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("Your photo was upgraded")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                    
                    Button {
                        // TODO: Implement Create Reel action
                    } label: {
                        Text("Create 8 Reel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color("AccentColor"))
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 12) {
                        Button {
                            // TODO: Save to Photos
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down")
                                Text("Save")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                        }
                        
                        Button {
                            // TODO: Share
                        } label: {
                            HStack {
                                Image(systemName: "shareplay") // SF Symbol: shareplay or square.and.arrow.up
                                Text("Share")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button {
                        // Action?
                    } label: {
                        Text("Try Another Style")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                }
                .background(Color(UIColor.secondarySystemBackground).opacity(0.15)) // Glassy look
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.bottom, -30) // extend below safe area
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Post Preview")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true)
    }
}
