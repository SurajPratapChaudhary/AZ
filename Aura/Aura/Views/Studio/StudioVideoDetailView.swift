
import SwiftUI
import AVKit

struct StudioVideoDetailView: View {
    let item: StudioHistoryResponse.StudioItem
    var onBack: () -> Void
    
    @State private var player: AVPlayer?
    @State private var showMusicSheet = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main) { _ in
                                player.seek(to: .zero)
                                player.play()
                            }
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // Buttons Overlay
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        // TODO: Save
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down")
                            Text("Save")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black.opacity(0.3)) // Darker for video overlay compatibility? Matches screenshot
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    
                    Button {
                        // TODO: Share
                    } label: {
                        HStack {
                            Image(systemName: "shareplay")
                            Text("Share")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black.opacity(0.3))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                }
                .padding(.horizontal, 20)
                
                Button {
                    showMusicSheet = true
                } label: {
                    Text("Add Music")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("AccentColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
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
                
                Text("Reel Preview")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal)
        }
        .onAppear {
            if let urlString = item.variants.first, let url = URL(string: urlString) {
                player = AVPlayer(url: url)
            }
        }
        .sheet(isPresented: $showMusicSheet) {
            if #available(iOS 16.0, *) {
                StudioMusicSheet()
                    .presentationDetents([.fraction(0.6), .large])
                    .presentationDragIndicator(.visible)
            } else {
                StudioMusicSheet()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    let mockItem = StudioHistoryResponse.StudioItem(
        id: "mockVideo",
        type: "video",
        status: "completed",
        created_at: "2024-01-01",
        output_urls: [
            JobStatusResponse.JobStatusData.OutputUrl(url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", type: "video", index: 0, rank: 0)
        ],
        style: "Cinematic"
    )
    
    StudioVideoDetailView(item: mockItem, onBack: {})
}
