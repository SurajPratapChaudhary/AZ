
import Foundation
import UIKit
import Combine

// MARK: - Models

struct PhotoJobResult: Codable {
    let jobId: String
    let style: AuraStyle?
    let variants: [URL]
    let status: JobStatus
    let errorMessage: String?
    
    enum JobStatus: String, Codable {
        case processing = "PROCESSING"
        case queued = "QUEUED"
        case completed = "COMPLETED"
        case failed = "FAILED"
    }
}

struct JobResponse: Codable {
    let success: Bool?
    let message: String?
    let data: JobData?
    
    var job_id: String {
        return data?.job_id ?? ""
    }
    
    var status: String {
        return data?.status ?? ""
    }
    
    struct JobData: Codable {
        let job_id: String
        let status: String
        let credits_remaining: Int?
    }
}

struct JobStatusResponse: Codable {
    let success: Bool?
    let message: String?
    let data: JobStatusData?
    
    struct JobStatusData: Codable {
        let job_id: String
        let type: String
        let status: String
        let output_urls: [OutputUrl]?
        let error_message: String?
        
        struct OutputUrl: Codable {
            let url: String
            let type: String?
            let index: Int?
            let rank: Int?
        }
    }
}

struct LoginResponse: Codable {
    let success: Bool?
    let message: String?
    let data: LoginData?
    
    // Fallback/Direct properties for backward compatibility
    
    var access_token: String {
        return data?.access_token ?? ""
    }
    
    var user: User {
        return data?.user ?? User(id: "", email: "", credits: 0)
    }
    
    struct LoginData: Codable {
        let access_token: String
        let token_type: String
        let user: User
    }
    
    struct User: Codable {
        let id: String
        let email: String
        let credits: Int
    }
}

// MARK: - Studio Models
struct StudioHistoryResponse: Codable {
    let success: Bool
    let message: String?
    let data: StudioData
    
    // Computed property for backward compatibility with ViewModel
    var items: [StudioItem] {
        return data.jobs
    }
    
    struct StudioData: Codable {
        let jobs: [StudioItem]
        let total: Int
        let limit: Int
        let offset: Int
        let has_more: Bool
    }
    
    struct StudioItem: Codable, Identifiable {
        let id: String
        let type: String // "photo", "video", "mux"
        let status: String?
        let created_at: String
        let output_urls: [JobStatusResponse.JobStatusData.OutputUrl]?
        let style: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "job_id"
            case type
            case status
            case created_at
            case output_urls
            case style
        }
        
        // Helper to get simple URL strings if needed
        var variants: [String] {
            return output_urls?.map { $0.url } ?? []
        }
    }
}

// MARK: - Credits Models
struct CreditsResponse: Codable {
    let success: Bool?
    let message: String?
    let data: CreditsData?
    
    var credits: Int {
        return data?.balance ?? 0
    }
    
    var transactions: [Transaction]? {
        return data?.transactions
    }
    
    struct CreditsData: Codable {
        let balance: Int
        let transactions: [Transaction]?
    }
    
    struct Transaction: Codable, Identifiable {
        let id: String
        let amount: Int
        let type: String
        let description: String?
        let created_at: String
    }
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(statusCode: Int, message: String? = nil)
    case unknown
    case loginFailed(String)
}

protocol APIClientProtocol {
    func login(token: String, provider: String) async throws -> LoginResponse
    func enhanceShot(style: String, jpegData: Data) async throws -> String
    func generateReel(imagesData: [Data]) async throws -> String
    func getJobStatus(jobId: String) async throws -> PhotoJobResult?
    func getStudioHistory(limit: Int, offset: Int) async throws -> StudioHistoryResponse
    func getCredits() async throws -> CreditsResponse
    func muxMusic(audioUrl: URL, videoUrl: URL) async throws -> URL
    
    // Kept for backward compatibility
    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String
    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult?
}

final class APIClient: APIClientProtocol {
    private let baseURL = URL(string: "https://aura.zbekz.com")!
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 180 // Increased to 3 minutes for large uploads
        config.timeoutIntervalForRequest = 180
        self.session = URLSession(configuration: config)
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
        
        // Send style as is (Enum raw value)
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
    
    func generateReel(imagesData: [Data]) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/v1/jobs/generate-reel")
        Log.d("⬆️ REQUEST: \(url.absoluteString) | Images Count: \(imagesData.count)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "aura.authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        let lineBreak = "\r\n"
        
        for (index, data) in imagesData.enumerated() {
            body.append("--\(boundary + lineBreak)")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image_\(index).jpg\"\(lineBreak)")
            body.append("Content-Type: image/jpeg\(lineBreak + lineBreak)")
            body.append(data)
            body.append(lineBreak)
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                Log.e("❌ API generateReel failed: \(statusCode)")
                
                // Try to extract error message
                var errorMessage: String?
                if let errorJson = try? JSONDecoder().decode(JobResponse.self, from: data) {
                    errorMessage = errorJson.message
                }
                
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
        
        do {
            let response = try JSONDecoder().decode(JobStatusResponse.self, from: data)
            guard let jobData = response.data else {
                 Log.e("❌ JobStatusResponse missing data")
                 throw APIError.decodingError
            }
            
            // Map output objects to simple URLs
            let variants = jobData.output_urls?.compactMap { URL(string: $0.url) } ?? []
            
            return PhotoJobResult(
                jobId: jobData.job_id,
                style: nil,
                variants: variants,
                status: PhotoJobResult.JobStatus(rawValue: jobData.status) ?? .failed,
                errorMessage: jobData.error_message
            )
        } catch {
            Log.e("❌ Decoding Failed for JobStatus. Raw Response: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw error
        }
    }
    
    func getStudioHistory(limit: Int = 20, offset: Int = 0) async throws -> StudioHistoryResponse {
        var urlComp = URLComponents(string: baseURL.appendingPathComponent("/api/v1/jobs/studio").absoluteString)!
        urlComp.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "type", value: "all")
        ]
        
        guard let url = urlComp.url else { throw APIError.invalidURL }
        Log.d("API Studio History: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "aura.authToken") {
             request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown }
        
        if !(200...299).contains(httpResponse.statusCode) {
             if let errorString = String(data: data, encoding: .utf8) {
                 Log.e("API History Error: \(errorString)")
             }
             throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        logResponse(data, url: urlComp.url!.absoluteString)
        
        do {
            return try JSONDecoder().decode(StudioHistoryResponse.self, from: data)
        } catch {
            if let str = String(data: data, encoding: .utf8) {
                Log.e("❌ Decoding Failed for Studio History. Raw Response:\n\(str)")
            } else {
                Log.e("❌ Decoding Failed. Could not convert data to string.")
            }
            throw error
        }
    }
    
    
    // MARK: - Credits
    
    func getCredits() async throws -> CreditsResponse {
        let url = baseURL.appendingPathComponent("/api/v1/jobs/credits")
        Log.d("API Get Credits: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "aura.authToken") {
             request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }
        
        logResponse(data, url: url.absoluteString)
        return try JSONDecoder().decode(CreditsResponse.self, from: data)
    }
    
    func muxMusic(audioUrl: URL, videoUrl: URL) async throws -> URL {
        throw APIError.unknown
    }
    
    // MARK: - Legacy / Helper
    
    func createPhotoJob(style: AuraStyle, jpegData: Data) async throws -> String {
        return try await enhanceShot(style: style.rawValue, jpegData: jpegData)
    }

    func pollPhotoJob(jobId: String) async throws -> PhotoJobResult? {
        return try await getJobStatus(jobId: jobId)
    }
    
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
        if let str = String(data: data, encoding: .utf8) {
            Log.d("API Response [\(url)]: \(str)")
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
