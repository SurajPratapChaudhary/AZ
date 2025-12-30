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

    let cameraService: CameraService
    private let apiClient: APIClientProtocol
    private let selector = BestFrameSelector()
    private let guidanceService = GuidanceService()

    init(cameraService: CameraService = CameraService(), apiClient: APIClientProtocol = APIClient()) {
        self.cameraService = cameraService
        self.apiClient = apiClient
    }

    func setup() async {
        Log.d("setup()")

        cameraService.onVideoFrame = { [weak self] pb in
            Task { @MainActor in
                self?.guidanceService.ingestFrame(pb)
                self?.guidance = self?.guidanceService.state ?? .good
            }
        }

        guidanceService.start()
        Log.d("Guidance started")
        
        // Configure and start camera
        await cameraService.configure()
        await cameraService.start()
        Log.d("Camera started")
    }
    
    func cleanup() async {
        await cameraService.stop()
    }

    func shutterTapped() {
        guard !isCapturing else { return }
        isCapturing = true
        Log.d("Shutter tapped. style=\(selectedStyle.rawValue)")

        Task {
            defer {
                isCapturing = false
                Log.d("Capture flow finished (isCapturing=false)")
            }

            do {
                Log.d("Capturing burst...")
                let burst = try await cameraService.captureBurst(count: 10)
                Log.d("Burst captured frames=\(burst.count)")

                Log.d("Selecting best frame...")
                
                let picked = await Task.detached(priority: .userInitiated) {
                    let backgroundSelector = BestFrameSelector()
                    return backgroundSelector.selectBest(from: burst)
                }.value

                guard let picked else {
                    Log.e("BestFrameSelector returned nil")
                    return
                }

                Log.d("Best frame picked. scoreCount=\(picked.debugScores.count)")
                
                guard let rawImage = await Task.detached(priority: .userInitiated, operation: {
                    UIImage(data: picked.bestJPEG)
                }).value else {
                    Log.e("Failed to decode bestJPEG into UIImage")
                    return
                }

                Log.d("Creating photo job...")
                let jobId = try await apiClient.createPhotoJob(style: selectedStyle, jpegData: picked.bestJPEG)

                Log.d("Job created id=\(jobId)")
                state = .processing(rawPreview: rawImage, jobId: jobId)

            } catch {
                Log.e("Capture flow error: \(error.localizedDescription)")
                state = .camera
            }
        }
    }

    func pollUntilReady(jobId: String) async {
        Log.d("Polling job id=\(jobId)")

        guard case let .processing(raw, id) = state, id == jobId else { return }

        while true {
            if let result = try? await apiClient.pollPhotoJob(jobId: jobId), result.status == .completed {
                Log.d("Job completed id=\(jobId) variants=\(result.variants.count)")
                state = .results(result, rawPreview: raw)
                return
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }
}


struct CameraFlowView: View {
    @StateObject private var vm = CameraFlowViewModel()

    var body: some View {
        ZStack {
            switch vm.state {
            case .camera:
                CameraView(vm: vm)
                    .transition(.opacity)
            case .processing(let raw, let jobId):
                ProcessingView(rawPreview: raw, jobId: jobId)
                    .task { await vm.pollUntilReady(jobId: jobId) }
                    .transition(.opacity)
            case .results(let result, let raw):
                PhotoResultsView(rawPreview: raw, result: result)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.state.accessibilityLabel)
        .task {
            Log.d("CameraFlowView task start")
            await vm.setup()
        }
        .onChange(of: vm.state) { _, _ in
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.impactOccurred()
        }
        .onDisappear {
            Task { await vm.cleanup() }
        }
    }
}

// Helper for animation value
extension CameraFlowViewModel.State {
    var accessibilityLabel: String {
        switch self {
        case .camera: return "camera"
        case .processing: return "processing"
        case .results: return "results"
        }
    }
}

extension CameraFlowViewModel.State: Equatable {
    static func == (lhs: CameraFlowViewModel.State, rhs: CameraFlowViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera):
            return true
        case (.processing(_, let id1), .processing(_, let id2)):
            return id1 == id2
        case (.results(let r1, _), .results(let r2, _)):
            return r1.jobId == r2.jobId
        default:
            return false
        }
    }
}

