
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
            
            VStack(spacing: 0) {
                // Main Header
                HStack {
                    Button(action: onRetake) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
                
                // Grid of 4 images
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<min(variants.count, 4), id: \.self) { index in
                        AsyncImage(url: variants[index]) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    ProgressView()
                                        .tint(.white)
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(let error):
                                let _ = print("❌ Error loading image: \(variants[index]) desc: \(error.localizedDescription)")
                                Color.red.opacity(0.3)
                                    .overlay(
                                        Text("Failed")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    )
                            @unknown default:
                                Color.gray
                            }
                        }
                        .onAppear { Log.d("Loading variant: \(variants[index])") }
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedIndex == index ? Color.white : Color.clear, lineWidth: 3)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom Actions
                Button {
                    // In a real app, we'd load the UIImage from the URL or cache manager
                    // passing rawImage for now or we need to download it
                    // The viewmodel generateReel actually uses the Original Data, 
                    // so passing any image here is mostly for the 'starting' animation if needed.
                    onCreateReel(rawImage)
                    
                } label: {
                    HStack {
                        Image(systemName: "film")
                        Text("Create Video Reel")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
    }
}
