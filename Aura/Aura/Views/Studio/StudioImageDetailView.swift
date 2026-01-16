
import SwiftUI

struct StudioImageDetailView: View {
    @ObservedObject var vm: StudioViewModel
    let item: StudioHistoryResponse.StudioItem
    let selectedURL: URL?
    var onBack: () -> Void
    
    @State private var loadedImage: UIImage?
    
    init(vm: StudioViewModel, item: StudioHistoryResponse.StudioItem, selectedURL: URL? = nil, onBack: @escaping () -> Void) {
        self.vm = vm
        self.item = item
        self.selectedURL = selectedURL
        self.onBack = onBack
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch vm.state {
            case .generatingReel(let jobId, let image):
                ProcessingView(image: image, message: vm.progressMessage)
                    .task(id: jobId) { await vm.pollReelJob(jobId: jobId) }
                    .transition(.opacity)
                
            case .reelReady(let urls):
                VideoResultView(videoURLs: urls, onBack: {
                    vm.state = .idle
                })
                .transition(.opacity)
                
            case .idle:
                DetailContent()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: vm.state)
        .alert("Error", isPresented: $vm.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "An error occurred")
        }
    }
    
    @ViewBuilder func DetailContent() -> some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 24) {
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
                
                CreateReelButton()
                
                SaveShareButtons()
                
                Spacer()
                    .frame(height: 20)
            }
            .background(.ultraThinMaterial.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, content: TopArea)
        .navigationBarHidden(true)
        .background {
            if let url = selectedURL ?? item.variants.first.flatMap({ URL(string: $0) }) {
                ZStack {
                    AuraImageView(url: url)
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .screenWidth, maxHeight: .screenHeight)
                        .ignoresSafeArea()
                }
            } else {
                Text("No image found")
                    .foregroundStyle(.gray)
            }
        }
        .task {
            await loadImage()
        }
        .alert("Image Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The image has been saved to your Photos.")
        }
    }
    
    @ViewBuilder func CreateReelButton() -> some View {
        Button {
            if let img = loadedImage {
                vm.generateReel(from: img)
            }
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
        .disabled(loadedImage == nil)
    }
    
    @ViewBuilder func SaveShareButtons() -> some View {
        HStack(spacing: 12) {
            Button {
                saveImage()
            } label: {
                HStack {
                    Image(systemName: "arrow.down")
                    Text("Save")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(UIColor.systemGray6).opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            
            Button {
                shareImage()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(UIColor.systemGray6).opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder func TopArea() -> some View {
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
    
    @State private var showSaveAlert = false

    private func loadImage() async {
        // Determine URL logic (same as in body)
        let urlToLoad = selectedURL ?? item.variants.first.flatMap({ URL(string: $0) })
        
        guard let url = urlToLoad else { return }
        
        // Prevent redundant loading
        if loadedImage != nil { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.loadedImage = image
                }
            }
        } catch {
            print("Failed to load image data: \(error)")
        }
    }
    
    private func saveImage() {
        guard let image = loadedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showSaveAlert = true
    }
    
    private func shareImage() {
        guard let image = loadedImage else { return }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // Find top-most view controller to present from
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        // iPad support
        activityVC.popoverPresentationController?.sourceView = topVC.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        
        topVC.present(activityVC, animated: true)
    }
}

#Preview {
    let mockItem = StudioHistoryResponse.StudioItem(
        id: "mock1",
        type: "photo",
        status: "completed",
        created_at: "2024-01-01",
        output_urls: [
            JobStatusResponse.JobStatusData.OutputUrl(url: "https://media.istockphoto.com/id/500601834/photo/lake-moraine-and-canoe-dock-in-banff-national-park.jpg?s=612x612&w=0&k=20&c=TRuwRNk0hMinV-XA0pyvaZHKIhHEtdpGqzmcGy-VAlo=", type: "upscaled", index: 0, rank: 0)
        ],
        style: "Luxury"
    )
    
    StudioImageDetailView(vm: StudioViewModel(), item: mockItem, onBack: {})
}
