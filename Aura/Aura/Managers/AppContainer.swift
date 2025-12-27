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
    let fileStore = LocalFileStore()

    init(api: APIClientProtocol? = nil) {
        // Use SimulatedAPIClient for now to allow full flow testing without backend
        self.api = api ?? SimulatedAPIClient()
    }
}
