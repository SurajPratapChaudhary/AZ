//
//  PermissionManager.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import AVFoundation
import Photos
import UserNotifications
import Combine

@MainActor
final class PermissionManager: ObservableObject {
    enum PermissionState { case notDetermined, denied, authorized }

    @Published private(set) var camera: PermissionState = .notDetermined
    @Published private(set) var photos: PermissionState = .notDetermined
    @Published private(set) var notifications: PermissionState = .notDetermined

    func refresh() async {
        camera = Self.mapCamera(AVCaptureDevice.authorizationStatus(for: .video))
        photos = Self.mapPhotos(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        let notif = await UNUserNotificationCenter.current().notificationSettings()
        notifications = Self.mapNotif(notif.authorizationStatus)
    }

    func requestCamera() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await refresh()
        return granted
    }

    func requestPhotos() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await refresh()
        return Self.mapPhotos(status) == .authorized
    }

    func requestNotifications() async -> Bool {
        let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        await refresh()
        return granted ?? false
    }

    private static func mapCamera(_ s: AVAuthorizationStatus) -> PermissionState {
        switch s {
        case .authorized: return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func mapPhotos(_ s: PHAuthorizationStatus) -> PermissionState {
        switch s {
        case .authorized, .limited: return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func mapNotif(_ s: UNAuthorizationStatus) -> PermissionState {
        switch s {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}
