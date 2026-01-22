
import SwiftUI
import AVKit
import Combine

@MainActor
class VideoResultViewModel: ObservableObject {
    @Published var videoURLs: [URL]
    @Published var selectedReelIndex: Int = 0
    @Published var isMuxing: Bool = false
    @Published var progressMessage: String = ""
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    private let apiClient: APIClientProtocol
    
    init(videoURLs: [URL], apiClient: APIClientProtocol = APIClient()) {
        self.videoURLs = videoURLs
        self.apiClient = apiClient
    }
    
    func addDefaultMusic() {
        guard !videoURLs.isEmpty, videoURLs.indices.contains(selectedReelIndex) else { return }
        let currentURL = videoURLs[selectedReelIndex]
        
        Task {
            isMuxing = true
            progressMessage = "Adding Music..."
            
            do {
                let jobId = try await apiClient.muxMusic(videoUrl: currentURL)
                Log.d("Mux job started id=\(jobId)")
                await pollMuxJob(jobId: jobId, forIndex: selectedReelIndex)
            } catch let error as APIError {
                if case .sessionExpired = error {
                    isMuxing = false
                    return
                }
                Log.e("Mux start failed: \(error)")
                handleError("Failed to start music addition.")
            } catch {
                Log.e("Mux start failed: \(error)")
                handleError("Failed to start music addition.")
            }
        }
    }
    
    private func pollMuxJob(jobId: String, forIndex index: Int) async {
        let pollInterval: UInt64 = 2_000_000_000 // 2 seconds
        
        while true {
            do {
                if let result = try await apiClient.getJobStatus(jobId: jobId) {
                    if result.status == .completed {
                         if let newURL = result.variants.first {
                             Log.d("Mux success. New URL: \(newURL)")
                             // Update the URL for the specific index
                             if videoURLs.indices.contains(index) {
                                 videoURLs[index] = newURL
                             }
                             isMuxing = false
                             return
                         } else {
                             handleError("Music added but no URL returned.")
                             return
                         }
                    } else if result.status == .failed {
                        handleError(result.errorMessage ?? "Music addition failed.")
                        return
                    }
                }
            } catch let error as APIError {
                if case .sessionExpired = error {
                    isMuxing = false
                    return
                }
                Log.e("Polling mux error: \(error)")
            } catch {
                Log.e("Polling mux error: \(error)")
            }
            
            try? await Task.sleep(nanoseconds: pollInterval)
        }
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
        isMuxing = false
    }
}

struct VideoResultView: View {
    let onBack: () -> Void
    @StateObject private var vm: VideoResultViewModel
    
    @State private var player: AVPlayer?
    @State private var showMusicSheet = false
    
    init(videoURLs: [URL], onBack: @escaping () -> Void) {
        self.onBack = onBack
        self._vm = StateObject(wrappedValue: VideoResultViewModel(videoURLs: videoURLs))
    }
    
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
                Header()
                Spacer()
                BottomControls()
            }
            
            if vm.isMuxing {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text(vm.progressMessage)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear { setupPlayer() }
        .onChange(of: vm.selectedReelIndex) { _, _ in setupPlayer() }
        .onChange(of: vm.videoURLs) { _, _ in setupPlayer() }
        .onDisappear { player?.pause() }
        .sheet(isPresented: $showMusicSheet) {
            MusicSelectionView(onSelect: {
                vm.addDefaultMusic()
                showMusicSheet = false
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: $vm.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "Unknown error")
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
        .padding(.top, 50)
    }
    
    @ViewBuilder func BottomControls() -> some View {
        VStack(spacing: 20) {
            
            if vm.videoURLs.count > 1 {
                HStack(spacing: 30) {
                    ForEach(0..<vm.videoURLs.count, id: \.self) { index in
                        Button { vm.selectedReelIndex = index } label: {
                            VStack(spacing: 4) {
                                Text("Reel \(Character(UnicodeScalar(65 + index)!))")
                                    .font(.system(size: 16, weight: vm.selectedReelIndex == index ? .semibold : .regular))
                                    .foregroundStyle(vm.selectedReelIndex == index ? .white : .white.opacity(0.6))
                                
                                Rectangle()
                                    .fill(vm.selectedReelIndex == index ? Color("AccentColor") : Color.clear)
                                    .frame(width: 40, height: 2)
                            }
                        }
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
        guard !vm.videoURLs.isEmpty, vm.videoURLs.indices.contains(vm.selectedReelIndex) else { return }
        
        let url = vm.videoURLs[vm.selectedReelIndex]
        Log.d("Setting up player for: \(url)")
        
        // If same URL, don't recreate player to avoid glitch, but here we might WANT to reload if muxed
        // For simplicity, just recreate
        
        player?.pause()
        player = nil
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.play()
        self.player = newPlayer
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }
    }
    
    private func shareVideo() {
        guard !vm.videoURLs.isEmpty, vm.videoURLs.indices.contains(vm.selectedReelIndex) else { return }
        
        let url = vm.videoURLs[vm.selectedReelIndex]
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        rootVC.present(activityVC, animated: true)
    }
}

struct MusicSelectionView: View {
    let tracks = ["Default Music"]
    var onSelect: () -> Void
    
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
                
                Text("Available Tracks")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
                
                ScrollView {
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
                                    Text("Aura Original")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color("AccentColor"))
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                            .onTapGesture {
                                onSelect()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

#Preview {
//    VideoResultView(videoURLs: [], onBack: {})
}
