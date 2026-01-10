//
//  BestFrameSelector.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import UIKit
import Vision
import CoreImage

struct BestFrameSelector: Sendable {

    struct Result {
        let bestJPEG: Data
        let debugScores: [Double]
    }

    /// Safe frame normalized to top-left origin (0...1). Tweak later to match overlay precisely.
    private let safeFrame = CGRect(x: 0.18, y: 0.10, width: 0.64, height: 0.78)

    func selectBest(from burstJPEGs: [Data]) -> Result? {
        guard !burstJPEGs.isEmpty else { return nil }

        var scores: [Double] = []
        scores.reserveCapacity(burstJPEGs.count)

        var bestIndex = 0
        var bestScore = -Double.infinity

        for (i, data) in burstJPEGs.enumerated() {
            guard let img = UIImage(data: data),
                  let cg = img.cgImage else {
                scores.append(-999)
                continue
            }

            let sharp = sharpnessScore(cgImage: cg)        // 0..1
            let bright = brightnessScore(cgImage: cg)      // 0..1
            let face = faceInSafeFrameScore(cgImage: cg)   // 0..1

            // Weights (tweak anytime)
            let score = (0.70 * sharp) + (0.30 * bright) + (0.00 * face)

            scores.append(score)

            Log.d("Frame \(i) score=\(score) (sharp=\(sharp), bright=\(bright), face=\(face))")

            if score > bestScore {
                bestScore = score
                bestIndex = i
                Log.d("Best frame index=\(bestIndex) bestScore=\(bestScore)")
            }
        }

        Log.d("Final best frame index=\(bestIndex) bestScore=\(bestScore)")
        return .init(bestJPEG: burstJPEGs[bestIndex], debugScores: scores)
    }

    // MARK: - Sharpness (Laplacian variance on downsampled grayscale)
    private func sharpnessScore(cgImage: CGImage) -> Double {
        let size = 96
        guard let gray = downsampleToGrayscaleBytes(cgImage: cgImage, size: size) else {
            return 0
        }

        // Laplacian variance
        var sum: Double = 0
        var sumSq: Double = 0
        var count: Double = 0

        // 4-neighbor laplacian: -4c + up + down + left + right
        for y in 1..<(size - 1) {
            let row = y * size
            for x in 1..<(size - 1) {
                let idx = row + x
                let c = Double(gray[idx])
                let l = -4.0 * c
                    + Double(gray[idx - 1])
                    + Double(gray[idx + 1])
                    + Double(gray[idx - size])
                    + Double(gray[idx + size])

                sum += l
                sumSq += l * l
                count += 1
            }
        }

        let mean = sum / max(1, count)
        let variance = (sumSq / max(1, count)) - (mean * mean)

        // Normalize variance -> 0..1 (tweak scale if needed)
        // Typical useful range depends on image; 1200 is a decent start.
        let normalized = clamp(variance / 6000.0)
        return normalized
    }

    private func downsampleToGrayscaleBytes(cgImage: CGImage, size: Int) -> [UInt8]? {
        // 1 byte per pixel grayscale
        var bytes = [UInt8](repeating: 0, count: size * size)

        guard let ctx = CGContext(
            data: &bytes,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        ctx.interpolationQuality = .low
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        return bytes
    }

    // MARK: - Brightness (prefer mid-range)
    private func brightnessScore(cgImage: CGImage) -> Double {
        let size = 48
        guard let gray = downsampleToGrayscaleBytes(cgImage: cgImage, size: size) else { return 0.5 }

        let avg = gray.reduce(0.0) { $0 + Double($1) } / Double(gray.count) / 255.0 // 0..1

        // Prefer ~0.55 (not too dark, not blown out)
        let ideal = 0.55
        let dist = abs(avg - ideal)
        return max(0, 1.0 - (dist * 2.0))
    }

    // MARK: - Face in safe frame
    private func faceInSafeFrameScore(cgImage: CGImage) -> Double {
        let req = VNDetectFaceRectanglesRequest()

        // Orientation matters. For portrait camera captures this is usually .right.
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        try? handler.perform([req])

        guard let face = req.results?.first else {
            return 0.2 // small fallback so face detection failure doesn't kill the whole score
        }

        // Vision boundingBox is normalized with origin bottom-left.
        let bb = face.boundingBox
        let center = CGPoint(x: bb.midX, y: bb.midY)

        // Convert to top-left origin normalized
        let centerTopLeft = CGPoint(x: center.x, y: 1.0 - center.y)

        return safeFrame.contains(centerTopLeft) ? 1.0 : 0.0
    }

    private func clamp(_ v: Double) -> Double {
        min(1.0, max(0.0, v))
    }
}

