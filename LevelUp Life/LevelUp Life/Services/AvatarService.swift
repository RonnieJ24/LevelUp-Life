import Foundation
import SwiftUI
import Combine

/// Ready Player Me Avatar Service
/// Handles downloading, caching, and loading of RPM avatars
@MainActor
class AvatarService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentAvatarId: String?
    
    // MARK: - Configuration
    var verboseTelemetry = false
    var loaderKind: AvatarLoaderKind = .gltfKit2Loader
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        print("🚀 RPM: AvatarService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Load avatar by ID from Ready Player Me CDN using GLTFKit2
    func loadAvatar(avatarId: String) async {
        print("🔍 RPM: Preparing avatar with ID: \(avatarId) for GLTFKit2")
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Download GLB from RPM CDN
            let glbURL = try await downloadAvatarGLB(avatarId: avatarId)
            
            // Step 2: Store URL for GLTFKit2 to load
            currentAvatarId = avatarId
            GameState.shared.avatarState.localGlbPath = glbURL.path
            
            print("✅ RPM: Avatar ready for GLTFKit2 loading")
            
        } catch {
            print("❌ RPM: Failed to prepare avatar: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            
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
        print("📥 RPM: Downloading GLB for avatar: \(avatarId)")
        
        // Build CDN URL
        let cdnURL = ReadyPlayerMeConfig.modelURL(for: avatarId)
        guard let url = URL(string: cdnURL) else {
            throw AvatarError.invalidURL(cdnURL)
        }
        
        // Check cache first
        let cachedURL = try getCachedGLBURL(for: avatarId)
        if FileManager.default.fileExists(atPath: cachedURL.path) {
            print("✅ RPM: Using cached GLB: \(cachedURL.path)")
            return cachedURL
        }
        
        // Download from CDN
        let (data, response) = try await URLSession.shared.data(from: url)
        
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

enum AvatarError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case downloadFailed(Int)
    case fileTooSmall(Int)
    case glbLoadFailed(String)
    
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
        }
    }
}