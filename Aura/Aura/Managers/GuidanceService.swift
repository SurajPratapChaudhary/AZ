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
    private let faceCheckInterval: TimeInterval = 0.6

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
        // Brightness check (cheap)
        let bright = averageLuminance(pixelBuffer)
        let isLowLight = bright < 0.25

        // Stability check
        let isUnstable = lastMotionScore < 0.45

        // Face-in-frame check (throttled)
        var needsAdjust = false
        if Date().timeIntervalSince(lastFaceCheck) > faceCheckInterval {
            lastFaceCheck = Date()
            needsAdjust = !hasFaceCentered(pixelBuffer)
        }

        // Decide state priority
        if isLowLight { state = .lowLight; return }
        if isUnstable { state = .unstable; return }
        if needsAdjust { state = .adjustPosition; return }
        state = .good
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

    private func hasFaceCentered(_ pixelBuffer: CVPixelBuffer) -> Bool {
        let req = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([req])

        guard let face = (req.results as? [VNFaceObservation])?.first else { return false }

        // Safe frame normalized (rough, tweak later to match overlay)
        let safe = CGRect(x: 0.18, y: 0.10, width: 0.64, height: 0.78)

        let bb = face.boundingBox
        let center = CGPoint(x: bb.midX, y: bb.midY)
        let centerTopLeft = CGPoint(x: center.x, y: 1.0 - center.y)

        return safe.contains(centerTopLeft)
    }
}
