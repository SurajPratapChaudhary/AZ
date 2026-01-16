//
//  CachedImage.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 16/01/26.
//

import SwiftUI
import Kingfisher

struct CachedImage: View {
    
    let imageUrl: URL?
    
    init(imageUrl: String, expiration: StorageExpiration = .days(1)) {
        self.imageUrl = URL(string: imageUrl)
        configureCache(expiration: expiration)
    }
    
    init(url: URL?, expiration: StorageExpiration = .days(1)) {
        self.imageUrl = url
        configureCache(expiration: expiration)
    }
    
    private func configureCache(expiration: StorageExpiration) {
        Kingfisher.ImageCache.default.memoryStorage.config.countLimit = 100
        Kingfisher.ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        Kingfisher.ImageCache.default.memoryStorage.config.expiration = .expired
        Kingfisher.ImageCache.default.diskStorage.config.expiration = expiration
    }
    
    var body: some View {
        KFImage(imageUrl)
            .placeholder {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .shimmering(active: true)
                }
            }
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}

final class ImagePrefetcher {
    static let instance = ImagePrefetcher()
    var prefetchers: [String: Kingfisher.ImagePrefetcher] = [:]
    
    init() {}
    
    func startPrefetching(id: String, urls: [String]) {
        prefetchers[id] = Kingfisher.ImagePrefetcher(urls: urls.compactMap { URL(string: $0) })
        prefetchers[id]?.start()
    }
    
    func stopPrefetching(id: String) {
        prefetchers[id]?.stop()
    }
}


#Preview("Image") {
    CachedImage(imageUrl: "https://t.me/Westminster_group_Tashkent/664025")
}


//MARK: video checked

import SwiftUI
import Kingfisher
import AVKit

struct CachedImageForHome: View {
    let urlString: String
    @State private var isVideo: Bool = false
    
    init(imageUrl: String, expiration: StorageExpiration = .days(1)) {
        self.urlString = imageUrl
        Kingfisher.ImageCache.default.memoryStorage.config.countLimit = 100
        Kingfisher.ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        Kingfisher.ImageCache.default.memoryStorage.config.expiration = .expired
        Kingfisher.ImageCache.default.diskStorage.config.expiration = expiration
    }
    
    var body: some View {
        Group {
            if isVideo {
                VideoPlayerView(videoURL: URL(string: urlString)!)
            } else {
                KFImage(URL(string: urlString))
                    .placeholder {
                        ZStack {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .shimmering(active: true)
                        }
                    }
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .onAppear {
            checkIfVideo(url: urlString)
        }
    }
    
    private func checkIfVideo(url: String) {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm"]
        if let fileExtension = URL(string: url)?.pathExtension.lowercased() {
            isVideo = videoExtensions.contains(fileExtension)
        }
    }
}

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .aspectRatio(contentMode: .fill)
            .onAppear {
                let playerItem = AVPlayerItem(url: videoURL)
                player = AVPlayer(playerItem: playerItem)
                player?.actionAtItemEnd = .none
                player?.play()
                
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player?.currentItem,
                    queue: .main
                ) { _ in
                    player?.seek(to: .zero)
                    player?.play()
                }
            }
    }
}
