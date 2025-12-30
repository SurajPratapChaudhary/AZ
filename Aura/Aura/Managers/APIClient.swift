//
//  APIClient.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import Foundation
import UIKit
import Combine

// MARK: - Models

struct PhotoJobResult: Codable {
    let jobId: String
    let style: AuraStyle? // Optional as backend might not return it in all states
    let variants: [URL]
    let status: JobStatus
    
    enum JobStatus: String, Codable {
        case processing = "PROCESSING"
        case completed = "COMPLETED"
        case failed = "FAILED"
    }
}

// Internal response models
struct CreateJobResponse: Codable {
    let job_id: String
    let status: String
}

struct JobStatusResponse: Codable {
    let job_id: String
    let type: String
    let status: String
    let outputs: [String]? // URLs
}

struct UploadResponse: Codable {
    let url: String
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(statusCode: Int)
    case unknown
    case loginFailed(String)
}

struct LoginResponse: Codable {
    let access_token: String
    let token_type: String
    let user: User
    
    struct User: Codable {
        let id: String
        let email: String
        let credits: Int
    }
}

protocol APIClientProtocol {
    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String
    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult?
    func login(token: String, provider: String) async throws -> LoginResponse
}

final class APIClient: APIClientProtocol {
    private let baseURL = URL(string: "http://98.88.32.51:8000")! 
    private let session: URLSession
    
    // For demo/milestone 1, we might simply return a mock Upload URL if backend isn't ready
    // But consistent with "PROD READY CODE", we implement the network calls.
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String {
        // 1. Upload Image
        let imageURLString = try await uploadImage(data: jpegData)
        
        // 2. Create Job
        let url = baseURL.appendingPathComponent("jobs/photo")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Auth token would go here (M1: Basic Auth or Placeholder)
        // request.setValue("Bearer ...", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "style": style.rawValue,
            "image_url": imageURLString
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decode = try JSONDecoder().decode(CreateJobResponse.self, from: data)
        return decode.job_id
    }

    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult? {
        let url = baseURL.appendingPathComponent("jobs/\(jobId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
             // 404 might mean processing or invalid
            if (response as? HTTPURLResponse)?.statusCode == 404 { return nil }
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let statusResp = try JSONDecoder().decode(JobStatusResponse.self, from: data)
        
        let variants = statusResp.outputs?.compactMap { URL(string: $0) } ?? []
        
        // Map backend string status to enum
        let mappedStatus: PhotoJobResult.JobStatus
        switch statusResp.status.uppercased() {
        case "COMPLETED": mappedStatus = .completed
        case "FAILED": mappedStatus = .failed
        default: mappedStatus = .processing
        }
        
        if mappedStatus == .completed {
             return PhotoJobResult(jobId: jobId, style: nil, variants: variants, status: mappedStatus)
        }
        
        return nil // Return nil if not ready, or we could return a "Result" with status processing
    }
    
    func login(token: String, provider: String = "apple") async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("/api/v1/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "token": token,
            "provider": provider
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
             print("Login failed with status: \(httpResponse.statusCode)")
             if let errorString = String(data: data, encoding: .utf8) {
                 print("Error response: \(errorString)")
             }
             throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            return loginResponse
        } catch {
            print("Decoding error: \(error)")
            // Fallback debugging
            if let string = String(data: data, encoding: .utf8) {
                print("Raw Response: \(string)")
            }
            throw APIError.decodingError
        }
    }

    // MARK: - Private Helpers
    
    private func uploadImage(data: Data) async throws -> String {
        // In a real scenario, we might request a presigned URL then PUT
        // For M1, let's assume a direct /upload endpoint that returns the S3 URL
        
        let url = baseURL.appendingPathComponent("upload") // Placeholder endpoint
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = createMultipartBody(data: data, boundary: boundary, filename: "upload.jpg")
        
        // This makes the mock network call fail if the server doesn't exist.
        // For local testing without backend, we might want to return a fake URL after a delay if this fails?
        // But the user requested "RealApi client", so it SHOULD fail if backend is offline.
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
             throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        struct UploadResp: Codable { let url: String }
        let dec = try JSONDecoder().decode(UploadResp.self, from: responseData)
        return dec.url
    }
    
    private func createMultipartBody(data: Data, boundary: String, filename: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\(lineBreak)")
        body.append("Content-Type: image/jpeg\(lineBreak + lineBreak)")
        body.append(data)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
}

// Helper extension for Data append
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
