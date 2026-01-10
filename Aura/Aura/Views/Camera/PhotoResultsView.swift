
import SwiftUI

struct PhotoResultsView: View {
    let rawImage: UIImage
    let variants: [URL]
    let onRetake: () -> Void
    let onCreateReel: (UIImage) -> Void
    
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            MainImage()
            
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Handle
                    HStack {
                        Spacer()
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 4)
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    Text("Enhanced")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.leading, 20)
                    
                    Text("Your photo was upgraded")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.leading, 20)
                    
                    ThumbNails()
                    
                    CreateReelButton()
                    
                    SaveAndShareButtons()
                    
                    RetakeButton()
                }
                .background(Color.black.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.bottom, -30)
            }
        }
        .safeAreaInset(edge: .top, content: Header)
    }
    
    @ViewBuilder func Header() -> some View {
        VStack {
            HStack {
                Button(action: onRetake) {
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
            
            Spacer()
        }
    }
    
    @ViewBuilder func MainImage() -> some View {
        if !variants.isEmpty {
            AsyncImage(url: variants[selectedIndex]) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                case .failure:
                    // Fallback or Error
                    Color.gray
                        .overlay(Text("Failed to load").foregroundStyle(.white))
                case .empty:
                     ProgressView().tint(.white)
                @unknown default:
                    Color.gray
                }
            }
        } else {
            Image(uiImage: rawImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        }
    }
    
    @ViewBuilder func RetakeButton() -> some View {
        Button {
            onRetake()
        } label: {
            Text("Try Another Style")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }
    
    @ViewBuilder func SaveAndShareButtons() -> some View {
        HStack(spacing: 12) {
            Button {
                // Save logic
            } label: {
                Label("Save", systemImage: "arrow.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            
            Button {
                // Share logic
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder func ThumbNails() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Thumbnails")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.leading, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<variants.count, id: \.self) { index in
                        Button {
                            withAnimation { selectedIndex = index }
                        } label: {
                            AsyncImage(url: variants[index]) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Color.gray
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedIndex == index ? Color("AccentColor") : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder func CreateReelButton() -> some View {
        Button {
            onCreateReel(rawImage)
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
    }
}
