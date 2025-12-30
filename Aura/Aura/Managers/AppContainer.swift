//
//  AppContainer.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppContainer: ObservableObject {
    let permissions = PermissionManager()
    let camera = CameraService()
    let api: APIClientProtocol
    let auth: AuthService
    let fileStore = LocalFileStore()
    
    private var cancellables = Set<AnyCancellable>()

    init(api: APIClientProtocol? = nil) {
        let client = api ?? APIClient()
        self.api = client
        self.auth = AuthService(apiClient: client)
        
        // Forward AuthService changes to AppContainer to trigger UI updates
        self.auth.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
