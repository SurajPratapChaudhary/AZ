
import SwiftUI
import UIKit
import Combine
import AVFoundation

@MainActor
final class CameraFlowViewModel: ObservableObject {
    enum State: Equatable {
        case camera
        case mediaCaptured(image: UIImage) 
        case enhancing(rawPreview: UIImage, jobId: String)
        case variantsReady(PhotoJobResult, rawPreview: UIImage)
        case generatingReel(jobId: String, selectedImage: UIImage)
        case reelReady(videoURLs: [URL])
    }

    @Published var state: State = .camera
    @Published var selectedStyle: AuraStyle = .luxury
    @Published var guidance: GuidanceService.State = .good
    @Published var isCapturing: Bool = false
    @Published var captureProgress: Int = 0
    @Published var progressMessage: String = "Processing..."
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    let cameraService: CameraService
    private let apiClient: APIClientProtocol
    private let selector = BestFrameSelector()
    private let guidanceService = GuidanceService()
    
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
        Log.d("Shutter tapped.")

        Task {
            defer {
                isCapturing = false
                Log.d("Capture flow finished (isCapturing=false)")
            }

            do {
                Log.d("Capturing burst...")
                // Reset progress
                await MainActor.run { captureProgress = 0 }
                
                let burst = try await cameraService.captureBurst(count: 10) { [weak self] current in
                    Task { @MainActor in
                        self?.captureProgress = current
                    }
                }
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

                self.bestFrameData = picked.bestJPEG
                
                guard let rawImage = await Task.detached(priority: .userInitiated, operation: {
                    UIImage(data: picked.bestJPEG)
                }).value else {
                    Log.e("Failed to decode bestJPEG into UIImage")
                    return
                }
                
                // Stop camera and move to Preview/Style Select state
                await cameraService.stop()
                state = .mediaCaptured(image: rawImage)
                
            } catch {
                Log.e("Capture flow error: \(error.localizedDescription)")
                progressMessage = "Error: \(error.localizedDescription)"
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                reset()
            }
        }
    }
    
    func startEnhancement(style: AuraStyle) {
        guard case let .mediaCaptured(rawImage) = state, let jpegData = bestFrameData else {
            Log.e("Cannot start enhancement: wrong state or no data")
            return
        }
        
        Task {
             progressMessage = "Enhancing Shot..."
             Log.d("Enhancing shot with style: \(style.rawValue)")
             state = .enhancing(rawPreview: rawImage, jobId: "placeholder")
             
             do {
                 let jobId = try await apiClient.enhanceShot(style: style.rawValue, jpegData: jpegData)
                 Log.d("Enhance job created id=\(jobId)")
                 state = .enhancing(rawPreview: rawImage, jobId: jobId)
            } catch let error as APIError {
                if case .sessionExpired = error {
                    reset()
                    return
                }
                Log.e("Enhance request failed: \(error)")
                progressMessage = "Failed to start enhancement."
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                if case let .serverError(code, msg) = error {
                     if code == 402 {
                         errorMessage = msg ?? "Insufficient credits."
                     } else {
                         errorMessage = msg ?? "Server error: \(code)"
                     }
                } else {
                    errorMessage = error.localizedDescription
                }
                
                showErrorAlert = true
                state = .mediaCaptured(image: rawImage)
            } catch {
                Log.e("Enhance request failed: \(error)")
                progressMessage = "Failed to start enhancement."
                try? await Task.sleep(nanoseconds: 500_000_000)
                errorMessage = error.localizedDescription
                showErrorAlert = true
                state = .mediaCaptured(image: rawImage)
            }
        }
    }
    
    func pollEnhanceJob(jobId: String) async {
        guard jobId != "placeholder" else { return }
        Log.d("Polling enhance job id=\(jobId)")
        
        guard case let .enhancing(raw, id) = state, id == jobId else { return }
        
        guard case let .enhancing(raw, id) = state, id == jobId else { return }
        
        let pollInterval: UInt64 = 2_000_000_000
        
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
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        errorMessage = result.errorMessage ?? "Unknown error occurred."
                        showErrorAlert = true
                        reset()
                        return
                    }
                }
            } catch let error as APIError {
                if case .sessionExpired = error {
                    reset()
                    return
                }
                Log.e("Polling error: \(error)")
            } catch {
                Log.e("Polling error: \(error)")
            }
            
            try? await Task.sleep(nanoseconds: pollInterval)
        }
    }
    
    func generateReel(from image: UIImage) {
        guard case let .variantsReady(result, rawPreview) = state, !result.variants.isEmpty else {
            Log.e("No variants available for reel generation")
            return
        }
        
        // Capture data locally for restoration if needed
        let savedResult = result
        let savedRaw = rawPreview
        let variantURLs = result.variants
        
        Task {
            @MainActor in
            state = .generatingReel(jobId: "placeholder", selectedImage: image)
            progressMessage = "Downloading Images..."
            Log.d("Downloading \(variantURLs.count) variants for reel...")
            
            let imagesData: [Data] = await withTaskGroup(of: Data?.self) { group in
                for url in variantURLs {
                    group.addTask {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            return data
                        } catch {
                            Log.e("Failed to download variant: \(url) error: \(error)")
                            return nil
                        }
                    }
                }
                
                var results: [Data] = []
                for await data in group {
                    if let data = data {
                        results.append(data)
                    }
                }
                return results
            }
            
            guard !imagesData.isEmpty else {
                progressMessage = "Failed to download images."
                Log.e("No images downloaded successfully")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                state = .variantsReady(savedResult, rawPreview: savedRaw)
                showErrorAlert = true
                errorMessage = "Failed to download images. check internet."
                return
            }
            
            progressMessage = "Generating Reel..."
            
            do {
                let jobId = try await apiClient.generateReel(imagesData: imagesData)
                Log.d("Reel job created id=\(jobId)")
                state = .generatingReel(jobId: jobId, selectedImage: image)
                
            } catch let error as APIError {
                if case .sessionExpired = error {
                    reset()
                    return
                }
                Log.e("Generate reel error: \(error)")
                progressMessage = "Failed to start video generation."
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                if case let .serverError(code, msg) = error {
                     if code == 402 {
                         errorMessage = msg ?? "Insufficient credits."
                     } else {
                         errorMessage = msg ?? "Server error: \(code)"
                     }
                } else {
                    errorMessage = error.localizedDescription
                }
                
                showErrorAlert = true
                state = .variantsReady(savedResult, rawPreview: savedRaw)
            } catch {
                Log.e("Generate reel error: \(error)")
                progressMessage = "Failed to start video generation."
                try? await Task.sleep(nanoseconds: 500_000_000)
                errorMessage = error.localizedDescription
                showErrorAlert = true
                state = .variantsReady(savedResult, rawPreview: savedRaw)
            }
        }
    }
    
    func pollReelJob(jobId: String) async {
        guard jobId != "placeholder" else { return }
        Log.d("Polling reel job id=\(jobId)")
        
        guard case .generatingReel = state else { return }
        
        let pollInterval: UInt64 = 5_000_000_000 
        
        while true {
            guard case .generatingReel = state else { return }
            
            do {
                if let result = try await apiClient.getJobStatus(jobId: jobId) {
                    if result.status == .completed {
                        if !result.variants.isEmpty {
                            Log.d("Reel job completed variants=\(result.variants.count)")
                            state = .reelReady(videoURLs: result.variants)
                            return
                        } else {
                             Log.e("Reel job completed but no URLs found.")
                             progressMessage = "Video generation returned no file."
                             try? await Task.sleep(nanoseconds: 2_000_000_000)
                             reset()
                             return
                        }
                    } else if result.status == .failed {
                        progressMessage = "Video generation failed."
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        errorMessage = result.errorMessage ?? "Video generation failed."
                        showErrorAlert = true
                        reset()
                        return
                    }
                }
            } catch let error as APIError {
                if case .sessionExpired = error {
                    reset()
                    return
                }
                Log.e("Polling error: \(error)")
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
                
            case .mediaCaptured(let image):
                StyleSelectionView(image: image, onBack: {
                    vm.reset()
                }, onUpgrade: { style in
                    vm.startEnhancement(style: style)
                })
                .transition(.opacity)

            case .enhancing(let raw, let jobId):
                ProcessingView(image: raw, message: vm.progressMessage)
                    .task(id: jobId) { await vm.pollEnhanceJob(jobId: jobId) }
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
                    .task(id: jobId) { await vm.pollReelJob(jobId: jobId) }
                    .transition(.opacity)
                    
            case .reelReady(let urls):
                VideoResultView(videoURLs: urls, onBack: {
                    vm.reset()
                })
                .transition(.opacity)
            }
            
            if vm.isCapturing {
                 VStack {
                     HStack {
                         Spacer()
                         HStack(spacing: 8) {
                             if vm.captureProgress < 10 {
                                 ProgressView()
                                     .tint(.black)
                                     .scaleEffect(0.8)
                             }
                             Text(vm.captureProgress < 10 ? "Taking pictures: \(vm.captureProgress)/10" : vm.progressMessage)
                                 .font(.system(size: 14, weight: .medium))
                                 .foregroundStyle(.black)
                         }
                         .padding(.horizontal, 16)
                         .padding(.vertical, 10)
                         .background(Color.white.opacity(0.9))
                         .clipShape(Capsule())
                         .shadow(radius: 4)
                         Spacer()
                     }
                     .padding(.top, 60)
                     
                     Spacer()
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
        .alert("Error", isPresented: $vm.showErrorAlert) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text(vm.errorMessage)
        }
        .toolbar(vm.state == .camera ? .visible : .hidden, for: .tabBar)
    }
}

extension CameraFlowViewModel.State {
    var accessibilityLabel: String {
        switch self {
        case .camera: return "camera"
        case .mediaCaptured: return "mediaCaptured"
        case .enhancing: return "enhancing"
        case .variantsReady: return "variantsReady"
        case .generatingReel: return "generatingReel"
        case .reelReady: return "reelReady"
        }
    }
}

extension CameraFlowViewModel.State {
    static func == (lhs: CameraFlowViewModel.State, rhs: CameraFlowViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera):
            return true
        case (.mediaCaptured, .mediaCaptured):
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

#Preview {
    CameraFlowView()
}
