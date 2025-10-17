import Foundation
import SwiftUI
import simd

/// Avatar loader types
enum AvatarLoaderKind: String, Codable {
    case glbLoader = "glbLoader"
    case usdzPreferred = "usdzPreferred"
    case gltfKit2Loader = "gltfKit2Loader"
}

/// Avatar state persisted in GameState
struct AvatarState: Codable {
    var avatarId: String?
    var localGlbPath: String?
    var localModelPath: URL? // Alias for compatibility
    var lastPreviewImagePath: String?
    var emotion: AvatarEmotion = .neutral
    var lastUpdated: Date = Date()
    
    // Avatar Workshop v1.1 - Viewer Settings
    var cameraOrbit: SIMD3<Float> = SIMD3<Float>(0, 0, 0) // yaw, pitch, radius
    var lightingPreset: String = "studio"
    var backgroundPreset: String = "black"
    var scaleMultiplier: Float = 1.0
    
    /// Check if avatar is loaded
    var isLoaded: Bool {
        return avatarId != nil && (localGlbPath != nil || localModelPath != nil)
    }
}

/// Diagnostics payload for telemetry
struct Diagnostics: Codable {
    var avatarId: String?
    var url: String
    var httpStatus: Int?
    var fileBytes: Int64?
    var mime: String?
    var loaderKind: String
    var errorCode: String
    var errorMessage: String
    var device: String
    var iOS: String
    var ts: Date
    
    init(avatarId: String? = nil, url: String, httpStatus: Int? = nil, fileBytes: Int64? = nil, mime: String? = nil, loaderKind: AvatarLoaderKind = .glbLoader, errorCode: String, errorMessage: String) {
        self.avatarId = avatarId
        self.url = url
        self.httpStatus = httpStatus
        self.fileBytes = fileBytes
        self.mime = mime
        self.loaderKind = loaderKind.rawValue
        self.errorCode = errorCode
        self.errorMessage = String(errorMessage.prefix(200)) // Limit to 200 chars
        self.device = UIDevice.current.model
        self.iOS = UIDevice.current.systemVersion
        self.ts = Date()
    }
}

/// Avatar emotional states for reactions
enum AvatarEmotion: String, CaseIterable, Codable {
    case neutral = "neutral"
    case happy = "happy"
    case sad = "sad"
    case proud = "proud"
    case celebrate = "celebrate"
    
    /// Color associated with emotion
    var moodColor: Color {
        switch self {
        case .neutral: return .gray
        case .happy: return .green
        case .sad: return .blue
        case .proud: return .purple
        case .celebrate: return .orange
        }
    }
    
    /// System image for emotion
    var systemImageName: String {
        switch self {
        case .neutral: return "face.smiling"
        case .happy: return "face.smiling.fill"
        case .sad: return "face.dashed"
        case .proud: return "star.fill"
        case .celebrate: return "party.popper.fill"
        }
    }
}