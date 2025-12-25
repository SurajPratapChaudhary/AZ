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
        self.api = api ?? MockAPIClient(fileStore: fileStore)
    }
}
