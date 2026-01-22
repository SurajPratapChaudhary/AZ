
import SwiftUI
import Combine

@MainActor
final class StudioViewModel: ObservableObject {
    
    struct StudioGridItem: Identifiable, Equatable {
        let id: String
        let url: URL
        let type: String
        let originalItem: StudioHistoryResponse.StudioItem
        
        static func == (lhs: StudioGridItem, rhs: StudioGridItem) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    @Published var items: [StudioGridItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var canLoadMore: Bool = true
    
    private let apiClient: APIClientProtocol
    private var offset: Int = 0
    private let limit: Int = 20
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchHistory(isRefresh: Bool = false) async {
        if isRefresh {
            offset = 0
            items.removeAll()
            canLoadMore = true
        }
        
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getStudioHistory(limit: limit, offset: offset)
            
            if response.items.isEmpty {
                canLoadMore = false
            } else {
                // Flatten items
                let newGridItems = response.items.flatMap { item -> [StudioGridItem] in
                    // If output_urls exists, map each to a grid item
                    if let outputs = item.output_urls, !outputs.isEmpty {
                        return outputs.compactMap { output in
                            if let url = URL(string: output.url) {
                                return StudioGridItem(
                                    id: "\(item.id)_\(output.index ?? 0)",
                                    url: url,
                                    type: output.type ?? item.type,
                                    originalItem: item
                                )
                            }
                            return nil
                        }
                    } else if !item.variants.isEmpty {
                        // Fallback to legacy variants strings if output_urls is missing 
                         return item.variants.enumerated().compactMap { index, urlString in
                             if let url = URL(string: urlString) {
                                 return StudioGridItem(
                                     id: "\(item.id)_\(index)",
                                     url: url,
                                     type: item.type,
                                     originalItem: item
                                 )
                             }
                             return nil
                         }
                    }
                    return []
                }
                
                self.items.append(contentsOf: newGridItems)
                self.offset += response.items.count
                
                if response.items.count < limit {
                    canLoadMore = false
                }
            }
            
        } catch let error as APIError {
            if case .sessionExpired = error {
                // Session expired - ContentView will handle navigation to AuthView
                return
            }
            print("Studio fetch error: \(error)")
            self.errorMessage = "Failed to load studio history."
        } catch {
            print("Studio fetch error: \(error)")
            self.errorMessage = "Failed to load studio history."
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await fetchHistory(isRefresh: true)
    }
    
    enum State: Equatable {
        case idle
        case generatingReel(jobId: String, selectedImage: UIImage)
        case reelReady(videoURLs: [URL])
        
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.generatingReel(let id1, _), .generatingReel(let id2, _)): return id1 == id2
            case (.reelReady(let u1), .reelReady(let u2)): return u1 == u2
            default: return false
            }
        }
    }
    
    @Published var state: State = .idle
    @Published var progressMessage: String = ""
    @Published var showErrorAlert: Bool = false
    
    func generateReel(from image: UIImage) {
        let imageData = image.jpegData(compressionQuality: 0.9)
        
        Task {
            state = .generatingReel(jobId: "placeholder", selectedImage: image)
            progressMessage = "Generating Reel..."
            
            guard let data = imageData else {
                 errorMessage = "Failed to process image."
                 showErrorAlert = true
                 state = .idle
                 return
            }
            
            do {
                let jobId = try await apiClient.generateReel(imagesData: [data])
                state = .generatingReel(jobId: jobId, selectedImage: image)
                
            } catch let error as APIError {
                if case .sessionExpired = error {
                    state = .idle
                    return
                }
                print("Generate reel error: \(error)")
                progressMessage = "Failed to start video generation."
                try? await Task.sleep(nanoseconds: 500_000_000)
                errorMessage = "Failed to start video generation."
                showErrorAlert = true
                state = .idle
            } catch {
                print("Generate reel error: \(error)")
                progressMessage = "Failed to start video generation."
                try? await Task.sleep(nanoseconds: 500_000_000)
                errorMessage = "Failed to start video generation."
                showErrorAlert = true
                state = .idle
            }
        }
    }
    
    func pollReelJob(jobId: String) async {
        guard jobId != "placeholder" else { return }
        
        // Polling loop
        let pollInterval: UInt64 = 5_000_000_000
        
        while true {
            guard case .generatingReel = state else { return }
            
            do {
                if let result = try await apiClient.getJobStatus(jobId: jobId) {
                    if result.status == .completed {
                        if !result.variants.isEmpty {
                            state = .reelReady(videoURLs: result.variants)
                            return
                        } else {
                             progressMessage = "Video generation returned no file."
                             try? await Task.sleep(nanoseconds: 2_000_000_000)
                             state = .idle
                             return
                        }
                    } else if result.status == .failed {
                        progressMessage = "Video generation failed."
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        errorMessage = result.errorMessage ?? "Video generation failed."
                        showErrorAlert = true
                        state = .idle
                        return
                    }
                }
            } catch let error as APIError {
                if case .sessionExpired = error {
                    state = .idle
                    return
                }
                print("Polling error: \(error)")
            } catch {
                print("Polling error: \(error)")
            }
            
            try? await Task.sleep(nanoseconds: pollInterval)
        }
    }
    
    // Existing loadMoreContent...
    func loadMoreContent(currentItem item: StudioGridItem) {
        if let lastItem = items.last, lastItem.id == item.id {
             Task { await fetchHistory() }
        }
    }
}
