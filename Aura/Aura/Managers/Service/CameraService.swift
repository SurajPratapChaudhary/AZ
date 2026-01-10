//
//  CameraService.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import AVFoundation
import CoreImage
import UIKit
import Combine

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "aura.camera.session")
    private let videoQueue = DispatchQueue(label: "aura.camera.video")

    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()

    // Strong-retain in-flight delegates (critical)
    private var inFlightDelegates: [Int64: PhotoCaptureDelegate] = [:]
    private let delegatesLock = NSLock()
    private var nextCaptureId: Int64 = 0

    // Live frames for guidance
    var onVideoFrame: ((CVPixelBuffer) -> Void)?

    override init() {
        super.init()
    }

    // MARK: - Setup

    func configure() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else {
                    cont.resume()
                    return
                }
                
                Log.d("configure() begin")

                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                // Input
                guard
                    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                    let input = try? AVCaptureDeviceInput(device: device),
                    self.session.canAddInput(input)
                else {
                    Log.e("Failed to add camera input")
                    self.session.commitConfiguration()
                    cont.resume()
                    return
                }

                self.session.addInput(input)
                self.configureDevice(device)

                // Photo output
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    if let maxDim = device.activeFormat.supportedMaxPhotoDimensions.last {
                        self.photoOutput.maxPhotoDimensions = maxDim
                    }
                    // Enable concurrent captures if supported (optimizes burst)
                    if self.photoOutput.isContentAwareDistortionCorrectionSupported {
                        self.photoOutput.isContentAwareDistortionCorrectionEnabled = false // Speed up
                    }
                    Log.d("PhotoOutput added. Concurrent support likely: \(self.photoOutput.maxBracketedCapturePhotoCount > 1)")
                } else {
                    Log.e("Cannot add PhotoOutput")
                }

                // Video output (guidance only)
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.videoQueue)

                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                    if let c = self.videoOutput.connection(with: .video) {
                        c.videoRotationAngle = 90 // portrait
                    }
                    Log.d("VideoDataOutput added")
                } else {
                    Log.e("Cannot add VideoDataOutput")
                }

                self.session.commitConfiguration()
                Log.d("configure() committed")

                cont.resume()
            }
            
            sessionQueue.async(execute: workItem)
        }
    }

    func start() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                if !self.session.isRunning {
                    Log.d("session.startRunning()")
                    self.session.startRunning()
                } else {
                    Log.d("session already running")
                }
                cont.resume()
            }
        }
    }

    func stop() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                if self.session.isRunning {
                    Log.d("session.stopRunning()")
                    self.session.stopRunning()
                }
                cont.resume()
            }
        }
    }

    // MARK: - Photo capture (single)
    func capturePhotoJPEG(prioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced) async throws -> Data {
        // Ensure session is running
        guard session.isRunning else {
            Log.e("capturePhotoJPEG called while session not running")
            throw NSError(domain: "AuraCamera", code: -10)
        }

        let captureId = nextId()

        return try await withCheckedThrowingContinuation { cont in
            // Log.d("captured start id=\(captureId)") // Reduced logs for speed

            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            if self.photoOutput.maxPhotoDimensions.width > 0 {
                settings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
            }
            settings.photoQualityPrioritization = prioritization

            let delegate = PhotoCaptureDelegate(captureId: captureId) { [weak self] result in
                guard let self else { return }
                self.removeDelegate(captureId)

                switch result {
                case .success(let data):
                    cont.resume(returning: data)
                case .failure(let error):
                    Log.e("capturePhotoJPEG failure id=\(captureId) err=\(error.localizedDescription)")
                    cont.resume(throwing: error)
                }
            }

            self.storeDelegate(delegate, captureId)

            // Must run on session queue? No, capturePhoto is thread safe but best practice to ensure session is valid.
            // We trust the caller or concurrency model.
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    // MARK: - Burst capture (~10 frames)
    /// Captures `count` frames as fast as possible.
    func captureBurst(count: Int = 10, onProgress: ((Int) -> Void)? = nil) async throws -> [Data] {
        Log.d("captureBurst start count=\(count)")
        var shots: [Data] = []
        shots.reserveCapacity(count)
        
        // Use .speed for faster capture (less processing time)
        let prioritization: AVCapturePhotoOutput.QualityPrioritization = .speed
        
        for i in 0..<count {
            do {
                // We still await, but .speed makes it faster.
                // We notify progress immediately after 'successful' capture return (which implies shutter fired + processed)
                // For PERCEIVED speed, we might want to update UI earlier?
                // The issue: await capturePhotoJPEG waits for DATA.
                // But we want to show "Capturing 1/10" moving.
                let jpeg = try await capturePhotoJPEG(prioritization: prioritization)
                shots.append(jpeg)
                onProgress?(i + 1)
            } catch {
                Log.e("burst shot \(i+1)/\(count) failed: \(error.localizedDescription)")
                // Continue to salvage burst
            }
        }
        
        if shots.isEmpty {
            Log.e("captureBurst failed: no frames captured")
            throw NSError(domain: "AuraCamera", code: -20)
        }
        
        Log.d("captureBurst end frames=\(shots.count)")
        return shots
    }

    // MARK: - Helpers
    private func configureDevice(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { device.whiteBalanceMode = .continuousAutoWhiteBalance }
            device.unlockForConfiguration()
        } catch {
            Log.e("configureDevice error: \(error.localizedDescription)")
        }
    }

    private func nextId() -> Int64 {
        delegatesLock.lock()
        defer { delegatesLock.unlock() }
        nextCaptureId += 1
        return nextCaptureId
    }

    private func storeDelegate(_ delegate: PhotoCaptureDelegate, _ id: Int64) {
        delegatesLock.lock()
        inFlightDelegates[id] = delegate
        delegatesLock.unlock()
    }

    private func removeDelegate(_ id: Int64) {
        delegatesLock.lock()
        inFlightDelegates.removeValue(forKey: id)
        delegatesLock.unlock()
    }
}

// MARK: - Video frames delegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onVideoFrame?(pb)
    }
}

// MARK: - Photo delegate (guarantees completion exactly once)
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let captureId: Int64
    private let completion: (Result<Data, Error>) -> Void

    private var data: Data?
    private var finished = false

    init(captureId: Int64, completion: @escaping (Result<Data, Error>) -> Void) {
        self.captureId = captureId
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            completeOnce(.failure(error))
            return
        }

        if let d = photo.fileDataRepresentation() {
            self.data = d
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        if let error {
            completeOnce(.failure(error))
            return
        }

        if let data {
            completeOnce(.success(data))
        } else {
            completeOnce(.failure(NSError(domain: "AuraCamera", code: -1)))
        }
    }

    private func completeOnce(_ result: Result<Data, Error>) {
        guard !finished else { return }
        finished = true
        completion(result)
    }
}
