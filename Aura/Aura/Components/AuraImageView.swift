import SwiftUI
import Combine

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let url: URL
    private var cancellable: AnyCancellable?
    
    init(url: URL) {
        self.url = url
    }
    
    func load() {
        if let cachedImage = ImageCache.shared.object(forKey: url.absoluteString as NSString) {
            self.image = cachedImage
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedImage in
                guard let self = self else { return }
                self.isLoading = false
                
                if let loadedImage = loadedImage {
                    ImageCache.shared.setObject(loadedImage, forKey: self.url.absoluteString as NSString)
                    self.image = loadedImage
                } else {
                    self.errorMessage = "Failed to load"
                }
            }
    }
    
    func cancel() {
        cancellable?.cancel()
        isLoading = false
    }
}

struct AuraImageView: View {
    let url: URL?
    
    @StateObject private var loader: ImageLoader
    
    init(url: URL?) {
        self.url = url
        _loader = StateObject(wrappedValue: ImageLoader(url: url ?? URL(string: "https://placeholder")!))
    }
    
    var body: some View {
        Group {
            if let _ = url {
                content
            } else {
                Color.gray
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let image = loader.image {
            Image(uiImage: image)
                .resizable()
        } else if loader.isLoading {
            ZStack {
                Color.gray.opacity(0.3)
                ProgressView()
                    .tint(.white)
            }
        } else if let _ = loader.errorMessage {
            ZStack {
                Color.gray
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.white)
            }
        } else {
            // Idle state, not started yet
            Color.gray.opacity(0.3)
                .onAppear {
                    loader.load()
                }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AuraImageView(url: URL(string: "https://via.placeholder.com/150"))
            .frame(width: 150, height: 150)
        
        AuraImageView(url: nil)
            .frame(width: 150, height: 150)
    }
}
