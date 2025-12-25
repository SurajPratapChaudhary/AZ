//
//  APIClient.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import Foundation

struct PhotoJobResult {
    let jobId: String
    let style: AuraStyle
    let variants: [URL]   // local file URLs for mock; later CDN URLs
}

protocol APIClientProtocol {
    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String
    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult?
}

import Foundation
import UIKit

final class MockAPIClient: APIClientProtocol {
    private let fileStore: LocalFileStore
    private let variantGen = ImageVariantGenerator()

    private var jobs: [String: (start: Date, style: AuraStyle, jpeg: Data)] = [:]

    init(fileStore: LocalFileStore) {
        self.fileStore = fileStore
    }

    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String {
        let id = UUID().uuidString
        jobs[id] = (Date(), style, jpegData)
        Log.d("Mock createPhotoJob id=\(id) style=\(style.rawValue) bytes=\(jpegData.count)")
        return id
    }

    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult? {
        guard let job = jobs[jobId] else { return nil }

        // Simulate processing time
        if Date().timeIntervalSince(job.start) < 2.0 { return nil }

        // Generate 4 *different* local variants
        let variantData = variantGen.generateVariants(from: job.jpeg)
        if variantData.count < 4 {
            Log.e("Mock variants generation failed; falling back to duplicates")
        }

        let urls = try (0..<4).map { idx in
            let data = idx < variantData.count ? variantData[idx] : job.jpeg
            return try fileStore.write(data: data, ext: "jpg", name: "variant_\(idx)_\(jobId)")
        }

        Log.d("Mock pollPhotoJob done id=\(jobId) variants=\(urls.count)")
        return PhotoJobResult(jobId: jobId, style: job.style, variants: urls)
    }
}

