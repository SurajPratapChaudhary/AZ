import SwiftUI
import AVFoundation

struct StudioView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var selectedGridItem: StudioViewModel.StudioGridItem?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isLoading && vm.items.isEmpty {
                    LoadingView()
                } else if let error = vm.errorMessage {
                    ErrorView(error)
                } else if vm.items.isEmpty {
                    EmptyView()
                } else {
                    MainContent()
                }
            }
            .fullScreenCover(item: $selectedGridItem) { gridItem in
                if gridItem.type == "video" || gridItem.type == "mux" {
                    StudioVideoDetailView(item: gridItem.originalItem) {
                        selectedGridItem = nil
                    }
                } else {
                    StudioImageDetailView(vm: vm, item: gridItem.originalItem, selectedURL: gridItem.url) {
                        selectedGridItem = nil
                    }
                }
            }
            .navigationTitle("Studio")
            .navigationBarTitleDisplayMode(.inline)
            //            .toolbar {
            //                if #available(iOS 26.0, *) {
            //                    ToolbarSpacer(.flexible, placement: .principal)
            //                }
            //                ToolbarItem(placement: .principal) {
            //                       Text("Studio")
            //                        .font(.system(size: 24, weight: .bold, design: .rounded))
            //                                        .foregroundColor(.primary)
            //                   }
            //                if #available(iOS 26.0, *) {
            //                    ToolbarSpacer(.flexible, placement: .principal)
            //                }
            //            }
        }
        .task {
            if vm.items.isEmpty {
                await vm.fetchHistory()
            }
        }
    }
    
    //MARK: Main Content
    @ViewBuilder func MainContent() -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(vm.items, id: \.id) { item in
                    Button {
                        selectedGridItem = item
                    } label: {
                        StudioItemCard(item: item)
                    }
                    .buttonStyle(.bouncy)
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
    
    //MARK: empty view
    @ViewBuilder func EmptyView() -> some View {
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
    }
    
    //MARK: loading view
    @ViewBuilder func LoadingView() -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<10, id: \.self) { _ in
                    ZStack {
                        Color.gray.opacity(0.3)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shimmeringEffect(loading: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    //MARK: Error View
    @ViewBuilder func ErrorView(_ error: String) -> some View {
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
    }
}

//MARK: Item Card
struct StudioItemCard: View {
    let item: StudioViewModel.StudioGridItem
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                if item.type == "video" || item.type == "mux" {
                    VideoThumbnailView(videoURL: item.url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    AuraImageView(url: item.url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
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

//MARK: Item Thumbnail
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
