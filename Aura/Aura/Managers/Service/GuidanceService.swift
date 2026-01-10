//
//  GuidanceService.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import Foundation
import CoreMotion
import Vision
import UIKit
import CoreImage
import Combine

@MainActor
final class GuidanceService: ObservableObject {
    enum State: Equatable {
        case good
        case lowLight
        case unstable
        case adjustPosition
    }

    @Published private(set) var state: State = .good

    private let motion = CMMotionManager()
    private var lastMotionScore: Double = 1.0

    private var lastFaceCheck = Date.distantPast
    private let faceCheckInterval: TimeInterval = 0.5
    
    // Smoothing / Debouncing
    private var lastStateChange = Date()
    private let minStateDuration: TimeInterval = 1.2 // Message stays for at least 1.2s
    
    // Cache last face result to prevent "Good" flickering during throttle
    private var lastFaceState: State = .good

    func start() {
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 30.0
            motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                // Simple “stability”: rotation rate magnitude
                let r = data.rotationRate
                let mag = sqrt(r.x*r.x + r.y*r.y + r.z*r.z)
                // Normalize: lower is better
                self.lastMotionScore = max(0.0, min(1.0, 1.0 - (mag / 4.0)))
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }

    func ingestFrame(_ pixelBuffer: CVPixelBuffer) {
        // 1. Determine "Target" state based on current frame data
        let targetState: State = calculateTargetState(pixelBuffer)

        // 2. Smooth the transition
        // Only change state if:
        // a) The new state is "Good" (we want to recover fast if fixed? maybe not, preventing flicker is better)
        // b) Enough time has passed since last change (reading time)
        
        let now = Date()
        let timeSinceChange = now.timeIntervalSince(lastStateChange)
        
        if targetState != state {
            // If we are currently "targetState" (already set), ignore.
            // If we want to change:
            if timeSinceChange > minStateDuration {
                state = targetState
                lastStateChange = now
            }
            // ELSE: Keep showing old message so user has time to read it.
        }
    }
    
    private func calculateTargetState(_ pixelBuffer: CVPixelBuffer) -> State {
        // Brightness check (cheap)
        let bright = averageLuminance(pixelBuffer)
        if bright < 0.25 { return .lowLight }

        // Stability check
        if lastMotionScore < 0.45 { return .unstable }

        // Face-in-frame check (throttled)
        if Date().timeIntervalSince(lastFaceCheck) > faceCheckInterval {
            lastFaceCheck = Date()
            
            // Perform detection
            if let faceRect = detectFace(pixelBuffer) {
                // Face found, check if it's in safe frame
                if !isFaceSafe(faceRect) {
                    lastFaceState = .adjustPosition
                } else {
                    lastFaceState = .good
                }
            } else {
                // If face is nil, we assume scenery => safe.
                lastFaceState = .good
            }
        }
        
        // Return cached face state (which is valid for faceCheckInterval)
        // This prevents falling back to .good in between checks if we were in .adjustPosition
        return lastFaceState
    }

    // MARK: - Helpers

    private func averageLuminance(_ pixelBuffer: CVPixelBuffer) -> Double {
        let ci = CIImage(cvPixelBuffer: pixelBuffer).transformed(by: CGAffineTransform(scaleX: 0.15, y: 0.15))
        let avg = ci.applyingFilter("CIAreaAverage", parameters: [kCIInputExtentKey: CIVector(cgRect: ci.extent)])

        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(avg, toBitmap: &pixel, rowBytes: 4,
                           bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0
        return 0.2126*r + 0.7152*g + 0.0722*b
    }

    private func detectFace(_ pixelBuffer: CVPixelBuffer) -> CGRect? {
        let req = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([req])
        return req.results?.first?.boundingBox
    }

    private func isFaceSafe(_ bb: CGRect) -> Bool {
        // Safe frame normalized (rough, tweak later to match overlay)
        let safe = CGRect(x: 0.18, y: 0.10, width: 0.64, height: 0.78)

        let center = CGPoint(x: bb.midX, y: bb.midY)
        // Vision origin is bottom-left, UI is top-left.
        // But pure checking "contains" for X is same. Y needs flip.
        let centerTopLeft = CGPoint(x: center.x, y: 1.0 - center.y)

        return safe.contains(centerTopLeft)
    }
}
