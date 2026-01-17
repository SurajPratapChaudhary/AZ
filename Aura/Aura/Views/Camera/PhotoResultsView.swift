
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
                
                VStack(alignment: .leading, spacing: 22) {
                    
                    Text("Enhanced")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)

                    Text("Your photo was upgraded")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 16)

                    ThumbNails()
                    
                    CreateReelButton()
                        .padding(.horizontal, 16)

                    SaveAndShareButtons()
                        .padding(.horizontal, 16)
                    
                    RetakeButton()
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)
                .background(.ultraThinMaterial.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding()
            }
        }
        .safeAreaInset(edge: .top, content: Header)
        .alert("Image Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The image has been saved to your Photos.")
        }
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
            AuraImageView(url: variants[selectedIndex])
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .screenWidth, maxHeight: .screenHeight)
                .ignoresSafeArea()
        } else {
            Image(uiImage: rawImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .screenWidth, maxHeight: .screenHeight)
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
                Task { await saveSelectedImage() }
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
                Task { await shareSelectedImage() }
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
    }
    
    @ViewBuilder func ThumbNails() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thumbnails")
                .font(.system(size: 14))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<variants.count, id: \.self) { index in
                        Button {
                            withAnimation { selectedIndex = index }
                        } label: {
                            AuraImageView(url: variants[index])
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIndex == index ? Color("AccentColor") : Color.clear, lineWidth: 3)
                                )
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal, 16)
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
    }
    
    // MARK: - Helper Methods
    
    // Add logic to show alert
    @State private var showSaveAlert = false
    
    private func getSelectedUIImage() async -> UIImage? {
        if variants.isEmpty {
            return rawImage
        }
        
        guard variants.indices.contains(selectedIndex) else { return nil }
        let url = variants[selectedIndex]
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Failed to download image for action: \(error)")
            return nil
        }
    }
    
    private func saveSelectedImage() async {
        guard let image = await getSelectedUIImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showSaveAlert = true
        }
    }
    
    private func shareSelectedImage() async {
        guard let image = await getSelectedUIImage() else { return }
        
        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
            
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
            // iPad support
            activityVC.popoverPresentationController?.sourceView = windowScene.windows.first
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    PhotoResultsView(
        rawImage: UIImage(),
        variants: [
            URL(string: "https://media.istockphoto.com/id/154232673/photo/blue-ridge-parkway-scenic-landscape-appalachian-mountains-ridges-sunset-layers.jpg?s=612x612&w=0&k=20&c=m2LZsnuJl6Un7oW4pHBH7s6Yr9-yB6pLkZ-8_vTj2M0=")!,
            URL(string: "https://media.istockphoto.com/id/500601834/photo/lake-moraine-and-canoe-dock-in-banff-national-park.jpg?s=612x612&w=0&k=20&c=TRuwRNk0hMinV-XA0pyvaZHKIhHEtdpGqzmcGy-VAlo=")!
        ],
        onRetake: {},
        onCreateReel: { _ in }
    )
}
