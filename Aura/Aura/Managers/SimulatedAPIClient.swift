//
//  SimulatedAPIClient.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 25/12/25.
//

import Foundation
import UIKit

/// A simulation of the backend for testing flow without a real server.
/// Mimics network delays and state transitions.
final class SimulatedAPIClient: APIClientProtocol {
    
    private var jobs: [String: PhotoJobResult] = [:]

    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String {
        // Simulate upload latency
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let jobId = UUID().uuidString
        let variants = (1...4).map { _ in
            // Return a local temporary URL as a placeholder for a "cloud" image
            // In a real app we'd download, but here we just point to a dummy or the original if we stored it.
            // For visual demo, we might want to return the same image or a modified one if possible.
            // Since we don't have NanoManana locally, we will just return the file URL of the captured image 
            // if we had it, or just empty URLs that the view handles gracefully.
            // BETTER: We can mock it by saving the input data to a temp file and returning that.
            URL(string: "https://mock.com/variant.jpg")!
        }
        
        // Store job as processing initially
        jobs[jobId] = PhotoJobResult(jobId: jobId, style: style, variants: [], status: .processing)
        
        // Start a background task to "finish" the job after a few seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds processing
            // Save mock result
            // To make it look real, let's write the jpegData to a temp file so we can display it 4 times
            let tempDir = FileManager.default.temporaryDirectory
            let variants: [URL] = (1...4).map { i in
                let url = tempDir.appendingPathComponent("\(jobId)_variant_\(i).jpg")
                try? jpegData.write(to: url)
                return url
            }
            
            self.jobs[jobId] = PhotoJobResult(jobId: jobId, style: style, variants: variants, status: .completed)
        }
        
        return jobId
    }

    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult? {
        // Simulate network latency
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        return jobs[jobId]
    }
}
