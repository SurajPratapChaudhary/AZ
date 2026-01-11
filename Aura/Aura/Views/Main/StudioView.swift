import SwiftUI
import AVFoundation

struct StudioView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var selectedItem: StudioHistoryResponse.StudioItem?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("Studio")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    
                    if vm.isLoading && vm.items.isEmpty {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if let error = vm.errorMessage {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.white)
                            Button("Retry") {
                                Task { await vm.refresh() }
                            }
                            .buttonStyle(.bordered)
                        }
                        Spacer()
                    } else if vm.items.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 50))
                                .foregroundStyle(.gray.opacity(0.5))
                            Text("No history yet")
                                .font(.headline)
                                .foregroundStyle(.gray)
                            Text("Your enhanced photos and reels will appear here.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(vm.items, id: \.id) { item in
                                    StudioItemCard(item: item)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                        .onAppear {
                                            vm.loadMoreContent(currentItem: item)
                                        }
                                }
                                
                                if vm.isLoading && !vm.items.isEmpty {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await vm.refresh()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedItem) { item in
                if item.type == "video" || item.type == "mux" {
                    StudioVideoDetailView(item: item) {
                        selectedItem = nil
                    }
                } else {
                    StudioImageDetailView(item: item) {
                        selectedItem = nil
                    }
                }
            }
        }
        .task {
            if vm.items.isEmpty {
                await vm.fetchHistory()
            }
        }
    }
}

struct StudioItemCard: View {
    let item: StudioHistoryResponse.StudioItem
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                if let urlString = item.variants.first, let url = URL(string: urlString) {
                    if item.type == "video" || item.type == "mux" {
                         VideoThumbnailView(videoURL: url)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        AuraImageView(url: url)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: item.type == "video" || item.type == "mux" ? "play.circle" : "photo")
                    .font(.system(size: 10))
                Text(item.type == "video" || item.type == "mux" ? "Reel" : "Image")
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(10)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
            } else {
                ZStack {
                    Color.black.opacity(0.8)
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .task {
            if thumbnail == nil {
                await generateThumbnail()
            }
        }
    }
    
    private func generateThumbnail() async {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let (cgImage, _) = try await generator.image(at: time)
            await MainActor.run {
                self.thumbnail = UIImage(cgImage: cgImage)
            }
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }
}

#Preview {
    StudioView()
}
