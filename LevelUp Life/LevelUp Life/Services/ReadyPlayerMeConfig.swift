import Foundation

/// Ready Player Me Studio Configuration
/// Configure your app at https://studio.readyplayer.me to get your subdomain
struct ReadyPlayerMeConfig {
    
    // MARK: - Studio Configuration
    /// Your app's subdomain from Studio dashboard
    /// Get this from: https://studio.readyplayer.me → Your App → Subdomain
    static let RPM_SUBDOMAIN = "leveluplife" // Your Studio subdomain
    
    // MARK: - URLs
    static let baseURL = "https://\(RPM_SUBDOMAIN).readyplayer.me"
    static let modelsCDN = "https://models.readyplayer.me"
    
    /// Avatar Creator URL with Frame API (required for postMessage events)
    /// Frame API enables communication between WebView and native app
    static func creatorURL(withCacheBuster: Bool = true) -> String {
        // Try the simplest Ready Player Me URL format first
        let baseURL = "https://readyplayer.me/avatar"
        if withCacheBuster {
            let timestamp = Int(Date().timeIntervalSince1970)
            return "\(baseURL)?t=\(timestamp)"
        }
        return baseURL
    }
    
    // MARK: - API Endpoints
    /// Get 3D avatar model (GLB format)
    /// No authentication required for public avatars
    static func modelURL(for avatarId: String) -> String {
        return "\(modelsCDN)/\(avatarId).glb"
    }
    
    /// Get 2D render of avatar
    static func previewURL(for avatarId: String) -> String {
        return "\(modelsCDN)/\(avatarId).png"
    }
    
    // MARK: - Frame API Events
    /// Events sent from WebView to native app
    struct FrameEvents {
        static let frameReady = "v1.frame.ready"
        static let sceneReady = "v1.scene.ready"
        static let userSet = "v1.user.set"
        static let avatarExported = "v1.avatar.exported"
        static let avatarExportedNew = "v1.avatar.exportedNew"
    }
    
    // MARK: - Cache Configuration
    static let cacheDirectory = "avatars"
    static let minFileSizeBytes = 50 * 1024 // 50 KB minimum
    static let maxCacheAgeDays = 30
}
