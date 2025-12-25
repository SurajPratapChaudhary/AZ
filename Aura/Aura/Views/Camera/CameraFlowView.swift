//
//  CameraFlowView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class CameraFlowViewModel: ObservableObject {
    enum State {
        case camera
        case processing(rawPreview: UIImage, jobId: String)
        case results(PhotoJobResult, rawPreview: UIImage)
    }

    @Published var state: State = .camera
    @Published var selectedStyle: AuraStyle = .luxury
    @Published var guidance: GuidanceService.State = .good
    @Published var isCapturing: Bool = false

    private var container: AppContainer?
    private let selector = BestFrameSelector()
    private let guidanceService = GuidanceService()

    func bind(container: AppContainer) {
        self.container = container
        Log.d("bind(container)")

        container.camera.onVideoFrame = { [weak self] pb in
            Task { @MainActor in
                self?.guidanceService.ingestFrame(pb)
                self?.guidance = self?.guidanceService.state ?? .good
            }
        }

        guidanceService.start()
        Log.d("Guidance started")
    }

    func shutterTapped() {
        guard let container, !isCapturing else { return }
        isCapturing = true
        Log.d("Shutter tapped. style=\(selectedStyle.rawValue)")

        Task {
            defer {
                isCapturing = false
                Log.d("Capture flow finished (isCapturing=false)")
            }

            do {
                Log.d("Capturing burst...")
                let burst = try await container.camera.captureBurst(count: 10)
                Log.d("Burst captured frames=\(burst.count)")

                Log.d("Selecting best frame...")
                guard let picked = selector.selectBest(from: burst) else {
                    Log.e("BestFrameSelector returned nil")
                    return
                }

                Log.d("Best frame picked. scoreCount=\(picked.debugScores.count)")
                guard let rawImage = UIImage(data: picked.bestJPEG) else {
                    Log.e("Failed to decode bestJPEG into UIImage")
                    return
                }

                Log.d("Creating photo job (mock)...")
                let jobId = try await container.api.createPhotoJob(style: selectedStyle, jpegData: picked.bestJPEG)

                Log.d("Job created id=\(jobId)")
                state = .processing(rawPreview: rawImage, jobId: jobId)

            } catch {
                Log.e("Capture flow error: \(error.localizedDescription)")
                state = .camera
            }
        }
    }

    func pollUntilReady(jobId: String) async {
        guard let container else { return }
        Log.d("Polling job id=\(jobId)")

        guard case let .processing(raw, id) = state, id == jobId else { return }

        while true {
            if let result = try? await container.api.pollPhotoJob(jobId: jobId) {
                Log.d("Job completed id=\(jobId) variants=\(result.variants.count)")
                state = .results(result, rawPreview: raw)
                return
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }
}


struct CameraFlowView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var vm = CameraFlowViewModel()

    var body: some View {
        ZStack {
            switch vm.state {
            case .camera:
                CameraView(vm: vm)
            case .processing(let raw, let jobId):
                ProcessingView(rawPreview: raw, jobId: jobId)
                    .task { await vm.pollUntilReady(jobId: jobId) }
            case .results(let result, let raw):
                PhotoResultsView(rawPreview: raw, result: result)
            }
        }
        .task {
            Log.d("CameraFlowView task start")
            vm.bind(container: container)

            // IMPORTANT: await configure before start (fixes Fig errors + broken captures)
            await container.camera.configure()
            await container.camera.start()
            Log.d("Camera started")
        }
        .onDisappear {
            Task { await container.camera.stop() }
        }
    }
}

