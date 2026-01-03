
import Foundation
import UIKit
import Combine

// MARK: - Models

struct PhotoJobResult: Codable {
    let jobId: String
    let style: AuraStyle?
    let variants: [URL]
    let status: JobStatus
    
    enum JobStatus: String, Codable {
        case processing = "PROCESSING"
        case queued = "QUEUED"
        case completed = "COMPLETED"
        case failed = "FAILED"
    }
}

struct JobResponse: Codable {
    let job_id: String
    let status: String
}

struct JobStatusResponse: Codable {
    let status: String
    let urls: [String]?
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

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(statusCode: Int)
    case unknown
    case loginFailed(String)
}

protocol APIClientProtocol {
    func login(token: String, provider: String) async throws -> LoginResponse
    func enhanceShot(style: String, jpegData: Data) async throws -> String
    func generateReel(jpegData: Data) async throws -> String
    func getJobStatus(jobId: String) async throws -> PhotoJobResult?
    
    // Kept for backward compatibility if needed, but implementation will use enhanceShot
    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String
    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult?
}

final class APIClient: APIClientProtocol {
    private let baseURL = URL(string: "http://98.88.32.51:8000")!
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Auth
    
    func login(token: String, provider: String = "apple") async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("/api/v1/auth/login")
        Log.d("API Login request: \(url.absoluteString) provider: \(provider)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "token": token,
            "provider": provider
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        // Log Body (careful with sensitive token, maybe truncate)
        Log.d("API Login Body: \(body)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Log.e("API Login Error: No HTTP Response")
                throw APIError.unknown
            }
            
            Log.d("API Login Response Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                 if let errorString = String(data: data, encoding: .utf8) {
                     Log.e("API Login Error response: \(errorString)")
                 }
                 throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            // Log Response Data
            if let responseString = String(data: data, encoding: .utf8) {
                Log.d("API Login Response Body: \(responseString)")
            }
            
            return try JSONDecoder().decode(LoginResponse.self, from: data)
            
        } catch {
            Log.e("API Login Exception: \(error)")
            throw error
        }
    }
    
    // MARK: - Jobs
    
    func enhanceShot(style: String, jpegData: Data) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/v1/jobs/enhance-shot")
        Log.d("⬆️ REQUEST: \(url.absoluteString) | Style: \(style) | Data: \(jpegData.count) bytes")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "aura.authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = createMultipartBody(parameters: ["style": style],
                                     data: jpegData,
                                     boundary: boundary,
                                     filename: "image.jpg",
                                     mimeType: "image/jpeg",
                                     fileKey: "image")
        
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                Log.e("❌ API enhanceShot failed: \(statusCode)")
                logResponse(data, url: url.absoluteString)
                throw APIError.serverError(statusCode: statusCode)
            }
            
            logResponse(data, url: url.absoluteString)
            
            let jobResponse = try JSONDecoder().decode(JobResponse.self, from: data)
            return jobResponse.job_id
        } catch {
             Log.e("❌ API enhanceShot Exception: \(error)")
             throw error
        }
    }
    
    func generateReel(jpegData: Data) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/v1/jobs/generate-reel")
        Log.d("⬆️ REQUEST: \(url.absoluteString) | Data: \(jpegData.count) bytes")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "aura.authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // No text parameters, just the file
        let body = createMultipartBody(parameters: [:],
                                     data: jpegData,
                                     boundary: boundary,
                                     filename: "image.jpg",
                                     mimeType: "image/jpeg",
                                     fileKey: "image")
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                Log.e("❌ API generateReel failed: \(statusCode)")
                logResponse(data, url: url.absoluteString)
                throw APIError.serverError(statusCode: statusCode)
            }
            
            logResponse(data, url: url.absoluteString)
            
            let jobResponse = try JSONDecoder().decode(JobResponse.self, from: data)
            return jobResponse.job_id
        } catch {
            Log.e("❌ API generateReel Exception: \(error)")
            throw error
        }
    }
    
    func getJobStatus(jobId: String) async throws -> PhotoJobResult? {
        let url = baseURL.appendingPathComponent("/api/v1/jobs/status/\(jobId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "aura.authToken") {
             request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown }
        
        if !(200...299).contains(httpResponse.statusCode) {
             Log.e("❌ API getJobStatus failed: \(httpResponse.statusCode)")
             return nil 
        }
        
        logResponse(data, url: url.absoluteString)
        
        let statusResp = try JSONDecoder().decode(JobStatusResponse.self, from: data)
        let variants = statusResp.urls?.compactMap { URL(string: $0) } ?? []
        
        // Log status briefly to avoid spamming full body if not needed, but User requested full logs.
        // Pretty print handles it.
        
        let mappedStatus: PhotoJobResult.JobStatus
        switch statusResp.status.uppercased() {
        case "COMPLETED": mappedStatus = .completed
        case "FAILED": mappedStatus = .failed
        case "QUEUED": mappedStatus = .queued
        default: mappedStatus = .processing
        }
        
        return PhotoJobResult(jobId: jobId, style: nil, variants: variants, status: mappedStatus)
    }
    
    // Backward compatibility
    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String {
        return try await enhanceShot(style: style.rawValue, jpegData: jpegData)
    }
    
    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult? {
        // Return nil if not completed for compat with old loop
        let result = try await getJobStatus(jobId: jobId)
        if result?.status == .completed {
            return result
        }
        return nil
    }
    
    // MARK: - Helpers
    
    private func createMultipartBody(parameters: [String: String],
                                   data: Data,
                                   boundary: String,
                                   filename: String,
                                   mimeType: String,
                                   fileKey: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        
        for (key, value) in parameters {
            body.append("--\(boundary + lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
            body.append("\(value + lineBreak)")
        }
        
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(fileKey)\"; filename=\"\(filename)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak + lineBreak)")
        body.append(data)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
    
    private func logResponse(_ data: Data, url: String) {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            Log.d("⬇️ RESPONSE (\(url)):\n\(prettyString)")
        } else if let string = String(data: data, encoding: .utf8) {
            Log.d("⬇️ RESPONSE (\(url)) [Raw]:\n\(string)")
        }
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
