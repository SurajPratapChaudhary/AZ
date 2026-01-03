
import SwiftUI
import UIKit
import Combine
import AVFoundation

@MainActor
final class CameraFlowViewModel: ObservableObject {
    enum State {
        case camera
        case enhancing(rawPreview: UIImage, jobId: String)
        case variantsReady(PhotoJobResult, rawPreview: UIImage)
        case generatingReel(jobId: String, selectedImage: UIImage)
        case reelReady(videoURL: URL)
    }

    @Published var state: State = .camera
    @Published var selectedStyle: AuraStyle = .luxury
    @Published var guidance: GuidanceService.State = .good
    @Published var isCapturing: Bool = false
    @Published var progressMessage: String = "Processing..."

    let cameraService: CameraService
    private let apiClient: APIClientProtocol
    private let selector = BestFrameSelector()
    private let guidanceService = GuidanceService()
    
    // Store original best frame data for Reel generation
    private var bestFrameData: Data?

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
        
        await cameraService.configure()
        await cameraService.start()
        Log.d("Camera started")
    }
    
    func cleanup() async {
        await cameraService.stop()
    }
    
    func reset() {
        state = .camera
        progressMessage = "Processing..."
        bestFrameData = nil
        Task { await cameraService.start() }
    }

    func shutterTapped() {
        guard !isCapturing else { return }
        isCapturing = true
        progressMessage = "Capturing..."
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
                
                await MainActor.run { progressMessage = "Filtering Best Shot..." }

                Log.d("Selecting best frame...")
                
                let picked = await Task.detached(priority: .userInitiated) {
                    let backgroundSelector = BestFrameSelector()
                    return backgroundSelector.selectBest(from: burst)
                }.value

                guard let picked else {
                    Log.e("BestFrameSelector returned nil")
                    return
                }

                // Store for later Reel generation
                self.bestFrameData = picked.bestJPEG
                
                guard let rawImage = await Task.detached(priority: .userInitiated, operation: {
                    UIImage(data: picked.bestJPEG)
                }).value else {
                    Log.e("Failed to decode bestJPEG into UIImage")
                    return
                }
                
                await MainActor.run { progressMessage = "Enhancing Shot..." }

                Log.d("Enhancing shot...")
                // Stop camera while processing to save resources
                await cameraService.stop()
                
                let jobId = try await apiClient.enhanceShot(style: selectedStyle.rawValue, jpegData: picked.bestJPEG)

                Log.d("Enhance job created id=\(jobId)")
                state = .enhancing(rawPreview: rawImage, jobId: jobId)
                
            } catch {
                Log.e("Capture flow error: \(error.localizedDescription)")
                progressMessage = "Error: \(error.localizedDescription)"
                // Optionally show error alert here
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                reset()
            }
        }
    }
    
    func pollEnhanceJob(jobId: String) async {
        Log.d("Polling enhance job id=\(jobId)")
        
        guard case let .enhancing(raw, id) = state, id == jobId else { return }
        
        // 1-3 seconds polling suggested by user
        let pollInterval: UInt64 = 2_000_000_000 // 2 seconds
        
        while true {
            guard case .enhancing = state else { return }
            
            do {
                if let result = try await apiClient.getJobStatus(jobId: jobId) {
                    if result.status == .completed {
                        Log.d("Enhance job completed variants=\(result.variants.count)")
                        state = .variantsReady(result, rawPreview: raw)
                        return
                    } else if result.status == .failed {
                        Log.e("Enhance job failed")
                        progressMessage = "Enhancement failed."
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        reset()
                        return
                    }
                }
            } catch {
                Log.e("Polling error: \(error)")
            }
            
            try? await Task.sleep(nanoseconds: pollInterval)
        }
    }
    
    func generateReel(from image: UIImage) {
        guard let data = bestFrameData else {
            Log.e("No best frame data found for reel")
            return
        }
        
        Task {
            @MainActor in
            // Stop polling or any other state
            progressMessage = "Generating Reel..."
            
            do {
                let jobId = try await apiClient.generateReel(jpegData: data)
                Log.d("Reel job created id=\(jobId)")
                state = .generatingReel(jobId: jobId, selectedImage: image)
                
            } catch {
                Log.e("Generate reel error: \(error)")
                progressMessage = "Failed to start video generation."
            }
        }
    }
    
    func pollReelJob(jobId: String) async {
        Log.d("Polling reel job id=\(jobId)")
        
        guard case .generatingReel = state else { return }
        
        // 4-6 seconds polling suggested by user
        let pollInterval: UInt64 = 5_000_000_000 // 5 seconds
        
        while true {
            guard case .generatingReel = state else { return }
            
            do {
                if let result = try await apiClient.getJobStatus(jobId: jobId) {
                    if result.status == .completed {
                        // Check if we have urls
                        if let videoURL = result.variants.first {
                            Log.d("Reel job completed url=\(videoURL)")
                            state = .reelReady(videoURL: videoURL)
                            return
                        } else {
                             Log.e("Reel job completed but no URLs found.")
                             // Maybe return? Or wait? 
                             // If completed without URL, it's virtually failed for us.
                             progressMessage = "Video generation returned no file."
                             try? await Task.sleep(nanoseconds: 2_000_000_000)
                             reset()
                             return
                        }
                    } else if result.status == .failed {
                        progressMessage = "Video generation failed."
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        reset()
                        return
                    }
                }
            } catch {
                Log.e("Polling error: \(error)")
            }
            
            try? await Task.sleep(nanoseconds: pollInterval)
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
                
            case .enhancing(let raw, let jobId):
                ProcessingView(image: raw, message: vm.progressMessage)
                    .task { await vm.pollEnhanceJob(jobId: jobId) }
                    .transition(.opacity)
                    
            case .variantsReady(let result, let raw):
                PhotoResultsView(rawImage: raw, variants: result.variants, onRetake: {
                    vm.reset()
                }, onCreateReel: { selectedImage in
                   vm.generateReel(from: selectedImage)
                })
                .transition(.opacity)
                
            case .generatingReel(let jobId, let image):
                ProcessingView(image: image, message: vm.progressMessage)
                    .task { await vm.pollReelJob(jobId: jobId) }
                    .transition(.opacity)
                    
            case .reelReady(let url):
                VideoResultView(videoURL: url, onBack: {
                    vm.reset()
                })
                .transition(.opacity)
            }
            
            // Overlay for initial burst capture & filtering logic
            if vm.isCapturing {
                 Color.black.opacity(0.6).ignoresSafeArea()
                 VStack {
                     ProgressView()
                         .tint(.white)
                         .scaleEffect(1.5)
                     Text(vm.progressMessage)
                         .font(.headline)
                         .foregroundStyle(.white)
                         .padding(.top, 10)
                 }
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
        case .enhancing: return "enhancing"
        case .variantsReady: return "variantsReady"
        case .generatingReel: return "generatingReel"
        case .reelReady: return "reelReady"
        }
    }
}

extension CameraFlowViewModel.State: Equatable {
    static func == (lhs: CameraFlowViewModel.State, rhs: CameraFlowViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera):
            return true
        case (.enhancing(_, let id1), .enhancing(_, let id2)):
            return id1 == id2
        case (.variantsReady(let r1, _), .variantsReady(let r2, _)):
            return r1.jobId == r2.jobId
        case (.generatingReel(let id1, _), .generatingReel(let id2, _)):
            return id1 == id2
        case (.reelReady(let u1), .reelReady(let u2)):
            return u1 == u2
        default:
            return false
        }
    }
}
