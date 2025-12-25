//
//  ImageVariantGenerator.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import Foundation
import UIKit
import CoreImage

final class ImageVariantGenerator {
    private let context = CIContext()

    enum Preset: CaseIterable {
        case v1, v2, v3, v4
    }

    func generateVariants(from jpegData: Data) -> [Data] {
        guard let base = CIImage(data: jpegData) else { return [] }

        return Preset.allCases.compactMap { preset in
            guard let out = apply(preset: preset, to: base),
                  let cg = context.createCGImage(out, from: out.extent)
            else { return nil }

            let ui = UIImage(cgImage: cg)
            return ui.jpegData(compressionQuality: 0.92)
        }
    }

    private func apply(preset: Preset, to image: CIImage) -> CIImage? {
        // Mild changes (just to see 4 different outputs in UI)
        // Real Nano backend will replace this later.
        switch preset {
        case .v1:
            return image
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 1.05,
                    kCIInputSaturationKey: 1.05,
                    kCIInputBrightnessKey: 0.02
                ])

        case .v2:
            return image
                .applyingFilter("CIExposureAdjust", parameters: [
                    kCIInputEVKey: 0.25
                ])
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 1.10,
                    kCIInputSaturationKey: 1.00
                ])

        case .v3:
            return image
                .applyingFilter("CIVibrance", parameters: [
                    "inputAmount": 0.35
                ])
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 1.08,
                    kCIInputBrightnessKey: -0.01
                ])

        case .v4:
            return image
                .applyingFilter("CIHighlightShadowAdjust", parameters: [
                    "inputHighlightAmount": 0.85,
                    "inputShadowAmount": 0.35
                ])
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 1.06,
                    kCIInputSaturationKey: 0.98
                ])
        }
    }
}
