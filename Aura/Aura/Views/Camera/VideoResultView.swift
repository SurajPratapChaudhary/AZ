
import SwiftUI
import AVKit

struct VideoResultView: View {
    let videoURL: URL
    let onBack: () -> Void
    
    @State private var player: AVPlayer?
    @State private var showMusicSheet = false
    @State private var selectedReelTab = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
            }
            
            VStack {
                Spacer()
                BottomControls()
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { player?.pause() }
        .sheet(isPresented: $showMusicSheet) {
            MusicSelectionView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder func Header() -> some View {
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
    
    @ViewBuilder func BottomControls() -> some View {
        VStack(spacing: 20) {
            
            HStack(spacing: 30) {
                Button { selectedReelTab = 0 } label: {
                    VStack(spacing: 4) {
                        Text("Reel A")
                            .font(.system(size: 16, weight: selectedReelTab == 0 ? .semibold : .regular))
                            .foregroundStyle(.white)
                        
                        Rectangle()
                            .fill(selectedReelTab == 0 ? Color("AccentColor") : Color.clear)
                            .frame(width: 40, height: 2)
                    }
                }
                
                Button { selectedReelTab = 1 } label: {
                    VStack(spacing: 4) {
                        Text("Reel B")
                            .font(.system(size: 16, weight: selectedReelTab == 1 ? .semibold : .regular))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Rectangle()
                            .fill(selectedReelTab == 1 ? Color("AccentColor") : Color.clear)
                            .frame(width: 40, height: 2)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    //TODO: Save Logic
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
                    shareVideo()
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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
        
    }
    
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
    
    private func shareVideo() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let activityVC = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
        rootVC.present(activityVC, animated: true)
    }
}

struct MusicSelectionView: View {
    let tracks = [
        "Midnight Serenade", "Dawn's Embrace", "Afternoon Whispers",
        "Twilight Reflections", "Sunset Melodies", "Nocturnal Rhythm"
    ]
    
    let styles = ["Luxury", "Cinematic", "Clean", "Editorial", "Night"]
    @State private var selectedStyle = "Luxury"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).ignoresSafeArea()
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                
                Text("Add Sound Track")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    MusicStyles()
                }
                
                ScrollView {
                    Musics()
                }
            }
        }
    }
    
    @ViewBuilder func MusicStyles() -> some View {
        HStack(spacing: 12) {
            ForEach(styles, id: \.self) { style in
                Text(style)
                    .font(.system(size: 14, weight: selectedStyle == style ? .semibold : .regular))
                    .foregroundStyle(selectedStyle == style ? Color.black : Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedStyle == style ? Color("AccentColor") : Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .onTapGesture {
                        withAnimation { selectedStyle = style }
                    }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder func Musics() -> some View {
        VStack(spacing: 8) {
            ForEach(tracks, id: \.self) { track in
                HStack {
                    ZStack {
                        Color.white.opacity(0.1)
                        Image(systemName: "music.note")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                        Text("3:15")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .onTapGesture {
                    //TODO: music Select Logic
                    dismiss()
                }
            }
        }
        .padding(.top, 8)
        
    }
}

#Preview {
    NavigationStack {
        VideoResultView(
            videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
            onBack: {}
        )
    }
}
