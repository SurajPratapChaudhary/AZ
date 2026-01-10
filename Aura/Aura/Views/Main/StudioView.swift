
import SwiftUI

struct StudioView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var selectedItem: StudioHistoryResponse.StudioItem?
    
    // Grid Configuration
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
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
                            .padding(.bottom, 100) // Spacer for tab bar
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
            // Only fetch if empty to avoid reloading on tab switch
            if vm.items.isEmpty {
                await vm.fetchHistory()
            }
        }
    }
}

// Add Identifiable conformance extension if it's not already there, or rely on id from struct
//extension StudioHistoryResponse.StudioItem: Identifiable {}

struct StudioItemCard: View {
    let item: StudioHistoryResponse.StudioItem
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Image
            GeometryReader { geo in
                if let urlString = item.thumbnails?.first ?? item.urls?.first, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            
            // Badge
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
        .frame(height: 220) // Fixed height for grid interaction
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
