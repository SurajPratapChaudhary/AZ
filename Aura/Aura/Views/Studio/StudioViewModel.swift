
import SwiftUI
import Combine

@MainActor
final class StudioViewModel: ObservableObject {
    @Published var items: [StudioHistoryResponse.StudioItem] = []
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
                self.items.append(contentsOf: response.items)
                self.offset += response.items.count
                
                if response.items.count < limit {
                    canLoadMore = false
                }
            }
            
        } catch {
            print("Studio fetch error: \(error)")
            self.errorMessage = "Failed to load studio history."
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await fetchHistory(isRefresh: true)
    }
    
    func loadMoreContent(currentItem item: StudioHistoryResponse.StudioItem) {
        if let lastItem = items.last, lastItem.id == item.id {
             Task { await fetchHistory() }
        }
    }
}
