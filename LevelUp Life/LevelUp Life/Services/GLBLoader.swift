import Foundation
import SceneKit
import GLTFKit2

/// GLB Loader for Ready Player Me avatars using GLTFKit2
/// This loader only supports GLTFKit2 rendering - no placeholders
struct GLBLoader {
    
    /// Load a GLB file and create a SceneKit scene using GLTFKit2
    static func loadGLB(from url: URL) throws -> SCNScene {
        print("🔍 GLBLoader: Loading GLB with GLTFKit2 from: \(url.path)")
        
        do {
            // Create GLTFAsset from URL
            let asset = try GLTFAsset(url: url)
            print("✅ GLBLoader: GLTFAsset created successfully")
            
            // Create SceneKit scene from GLTFAsset
            let scene = try SCNScene(gltfAsset: asset)
            print("✅ GLBLoader: Scene created with \(scene.rootNode.childNodes.count) nodes")
            
            // Setup camera for avatar viewing
            setupCamera(for: scene)
            
            // Setup studio lighting
            setupSceneLighting(scene)
            
            return scene
            
        } catch {
            print("❌ GLBLoader: Failed to load GLB: \(error.localizedDescription)")
            throw GLBError.gltfKit2LoadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Scene Setup
    
    private static func setupCamera(for scene: SCNScene) {
        // Remove any existing cameras
        scene.rootNode.enumerateChildNodes { node, _ in
            if node.camera != nil {
                node.removeFromParentNode()
            }
        }
        
        // Add new camera positioned for avatar viewing
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 1.5, z: 3.5)
        cameraNode.look(at: SCNVector3(x: 0, y: 1, z: 0))
        scene.rootNode.addChildNode(cameraNode)
        
        print("✅ GLBLoader: Camera setup complete")
    }
    
    private static func setupSceneLighting(_ scene: SCNScene) {
        // Key light
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 1000
        keyLight.castsShadow = true
        keyLight.shadowRadius = 10
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.3)
        
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.position = SCNVector3(2, 3, 2)
        keyLightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(keyLightNode)
        
        // Fill light
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.intensity = 300
        fillLight.color = UIColor.systemBlue
        
        let fillLightNode = SCNNode()
        fillLightNode.light = fillLight
        fillLightNode.position = SCNVector3(-2, 2, -2)
        scene.rootNode.addChildNode(fillLightNode)
        
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 200
        ambientLight.color = UIColor.white
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        print("✅ GLBLoader: Studio lighting setup complete")
    }
}

// MARK: - Supporting Types

enum GLBError: LocalizedError {
    case gltfKit2LoadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .gltfKit2LoadFailed(let message):
            return "GLTFKit2 load failed: \(message)"
        }
    }
}