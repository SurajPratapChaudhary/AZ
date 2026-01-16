
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
                detailContent
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
    
    var detailContent: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                
                if let url = selectedURL ?? item.variants.first.flatMap({ URL(string: $0) }) {
                    ZStack {
                        AuraImageView(url: url)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 500)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                            .onAppear {
                                Task {
                                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                                        loadedImage = image
                                    }
                                }
                            }
                    }
                } else {
                    Text("No image found")
                        .foregroundStyle(.gray)
                }
                
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
                    
                     Spacer()
                        .frame(height: 20)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.bottom, -30)
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
    
    private func saveImage() {
        guard let image = loadedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        // Ideally show a toast
    }
    
    private func shareImage() {
        guard let image = loadedImage else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // On iPad, popover is required
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    let mockItem = StudioHistoryResponse.StudioItem(
        id: "mock1",
        type: "photo",
        status: "completed",
        created_at: "2024-01-01",
        output_urls: [
            JobStatusResponse.JobStatusData.OutputUrl(url: "https://via.placeholder.com/500", type: "upscaled", index: 0, rank: 0)
        ],
        style: "Luxury"
    )
    
    StudioImageDetailView(vm: StudioViewModel(), item: mockItem, onBack: {})
}
