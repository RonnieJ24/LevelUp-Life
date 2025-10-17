import Foundation
import SwiftUI
import Combine
import GLTFKit2
import WebKit

/// Ready Player Me Avatar Service
/// Handles downloading, caching, and loading of RPM avatars with robust error handling
@MainActor
class AvatarService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentAvatarId: String?
    @Published var gltfKit2Status: GLTFKit2Status = .unknown
    
    // MARK: - Configuration
    var verboseTelemetry = false
    var loaderKind: AvatarLoaderKind = .gltfKit2Loader
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var downloadTask: URLSessionDataTask?
    
    // MARK: - Initialization
    init() {
        print("🚀 RPM: AvatarService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Load avatar by ID from Ready Player Me CDN using GLTFKit2
    func loadAvatar(avatarId: String) async {
        print("🔍 RPM: Preparing avatar with ID: '\(avatarId)' for GLTFKit2")
        print("🔍 RPM: Avatar ID length: \(avatarId.count)")
        
        // Validate avatar ID before proceeding
        guard !avatarId.isEmpty else {
            print("❌ RPM: Empty avatar ID provided")
            errorMessage = "No avatar ID provided"
            gltfKit2Status = .error
            return
        }
        
        // Validate ID format: must be 24-character hex string
        let idRegex = "^[0-9a-f]{24}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", idRegex)
        
        guard predicate.evaluate(with: avatarId) else {
            print("❌ RPM: Invalid avatar ID format: '\(avatarId)' (must be 24-character hex)")
            errorMessage = "Invalid avatar ID format"
            gltfKit2Status = .error
            return
        }
        
        isLoading = true
        errorMessage = nil
        gltfKit2Status = .loading
        
        do {
            // Step 1: Download GLB from RPM CDN
            let glbURL = try await downloadAvatarGLB(avatarId: avatarId)
            
            // Step 2: Store URL for GLTFKit2 to load
            currentAvatarId = avatarId
            GameState.shared.avatarState.localGlbPath = glbURL.path
            
            // Step 3: Validate GLB file for GLTFKit2
            let isValid = try await validateGLBForGLTFKit2(glbURL)
            if isValid {
                gltfKit2Status = .ready
                print("✅ RPM: Avatar ready for GLTFKit2 loading")
            } else {
                gltfKit2Status = .error
                throw AvatarError.glbLoadFailed("GLB validation failed")
            }
            
        } catch {
            print("❌ RPM: Failed to prepare avatar: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            gltfKit2Status = .error
            
            // Send telemetry for debugging
            await sendTelemetry(avatarId: avatarId, error: error)
        }
        
        isLoading = false
    }
    
    /// Clear avatar cache
    func clearAvatarCache() {
        print("🧹 RPM: Clearing avatar cache")
        
        do {
            let cacheDir = try getCacheDirectory()
            let files = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
            
            for file in files {
                try FileManager.default.removeItem(at: file)
                print("🗑️ RPM: Deleted cached file: \(file.lastPathComponent)")
            }
            
            print("✅ RPM: Cache cleared successfully")
            
        } catch {
            print("❌ RPM: Failed to clear cache: \(error.localizedDescription)")
        }
    }
    
    /// Clear RPM cookies for debugging
    func clearRPMCookies() async {
        print("🧹 RPM: Clearing RPM cookies")
        
        let dataStore = WKWebsiteDataStore.default()
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        do {
            let records = try await dataStore.dataRecords(ofTypes: websiteDataTypes)
            let rpmRecords = records.filter { record in
                record.displayName.contains("readyplayer.me")
            }
            
            try await dataStore.removeData(ofTypes: websiteDataTypes, for: rpmRecords)
            print("✅ RPM: Cookies cleared for \(rpmRecords.count) RPM domains")
            
        } catch {
            print("❌ RPM: Failed to clear cookies: \(error.localizedDescription)")
        }
    }
    
    /// Get last cached avatar info
    func getLastCachedAvatarInfo() -> (path: String, size: Int)? {
        guard let avatarId = currentAvatarId else { return nil }
        
        do {
            let cacheDir = try getCacheDirectory()
            let glbURL = cacheDir.appendingPathComponent("\(avatarId).glb")
            
            if FileManager.default.fileExists(atPath: glbURL.path) {
                let attributes = try FileManager.default.attributesOfItem(atPath: glbURL.path)
                let size = attributes[.size] as? Int ?? 0
                return (path: glbURL.path, size: size)
            }
        } catch {
            print("❌ RPM: Failed to get cached avatar info: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    /// Download GLB from Ready Player Me CDN
    private func downloadAvatarGLB(avatarId: String) async throws -> URL {
        print("📥 RPM: Downloading GLB for avatar: '\(avatarId)'")
        print("📥 RPM: Avatar ID length: \(avatarId.count)")
        
        // Validate avatar ID before proceeding
        guard !avatarId.isEmpty else {
            print("❌ RPM: Empty avatar ID in download function")
            throw AvatarError.invalidAvatarId("Empty avatar ID")
        }
        
        // Build CDN URL
        let cdnURL = ReadyPlayerMeConfig.modelURL(for: avatarId)
        print("📥 RPM: CDN URL: \(cdnURL)")
        
        guard let url = URL(string: cdnURL) else {
            print("❌ RPM: Invalid CDN URL: \(cdnURL)")
            throw AvatarError.invalidURL(cdnURL)
        }
        
        // Check cache first
        let cachedURL = try getCachedGLBURL(for: avatarId)
        if FileManager.default.fileExists(atPath: cachedURL.path) {
            print("✅ RPM: Using cached GLB: \(cachedURL.path)")
            return cachedURL
        }
        
        // Download from CDN with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AvatarError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AvatarError.downloadFailed(httpResponse.statusCode)
            }
            
            // Validate file size (minimum 50KB)
            guard data.count > ReadyPlayerMeConfig.minFileSizeBytes else {
                throw AvatarError.fileTooSmall(data.count)
            }
            
            // Save to cache
            try data.write(to: cachedURL)
            print("✅ RPM: GLB downloaded and cached: \(data.count) bytes")
            
            return cachedURL
            
        } catch {
            // Clean up partial download
            if FileManager.default.fileExists(atPath: cachedURL.path) {
                try? FileManager.default.removeItem(at: cachedURL)
            }
            throw error
        }
    }
    
    /// Validate GLB file for GLTFKit2 compatibility
    private func validateGLBForGLTFKit2(_ url: URL) async throws -> Bool {
        print("🔍 RPM: Validating GLB for GLTFKit2: \(url.path)")
        
        do {
            // Try to create GLTFAsset to validate the file
            let asset = try GLTFAsset(url: url)
            print("✅ RPM: GLB validation successful - asset has \(asset.scenes.count) scenes")
            return true
        } catch {
            print("❌ RPM: GLB validation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get cached GLB URL for avatar ID
    private func getCachedGLBURL(for avatarId: String) throws -> URL {
        let cacheDir = try getCacheDirectory()
        return cacheDir.appendingPathComponent("\(avatarId).glb")
    }
    
    /// Get avatar cache directory
    private func getCacheDirectory() throws -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let avatarCacheDir = cacheDir.appendingPathComponent(ReadyPlayerMeConfig.cacheDirectory)
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: avatarCacheDir, withIntermediateDirectories: true)
        
        return avatarCacheDir
    }
    
    /// Send telemetry for debugging
    private func sendTelemetry(avatarId: String, error: Error) async {
        print("📊 RPM: Sending telemetry for avatar: \(avatarId)")
        
        let diagnostics = Diagnostics(
            avatarId: avatarId,
            url: "unknown",
            httpStatus: nil,
            fileBytes: nil,
            mime: nil,
            loaderKind: loaderKind,
            errorCode: "scene_load_failed",
            errorMessage: error.localizedDescription
        )
        
        // TODO: Implement actual telemetry endpoint
        print("📊 RPM: Telemetry payload: \(diagnostics)")
    }
}

// MARK: - Supporting Types

enum GLTFKit2Status {
    case unknown
    case loading
    case ready
    case error
    
    var displayText: String {
        switch self {
        case .unknown: return "GLTFKit2: Unknown"
        case .loading: return "GLTFKit2: Loading..."
        case .ready: return "GLTFKit2: OK"
        case .error: return "GLTFKit2: Error"
        }
    }
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .loading: return .blue
        case .ready: return .green
        case .error: return .red
        }
    }
}

enum AvatarError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case downloadFailed(Int)
    case fileTooSmall(Int)
    case glbLoadFailed(String)
    case invalidAvatarId(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server"
        case .downloadFailed(let statusCode):
            return "Download failed with status code: \(statusCode)"
        case .fileTooSmall(let size):
            return "File too small: \(size) bytes (minimum: \(ReadyPlayerMeConfig.minFileSizeBytes))"
        case .glbLoadFailed(let message):
            return "GLB loading failed: \(message)"
        case .invalidAvatarId(let message):
            return "Invalid avatar ID: \(message)"
        }
    }
}