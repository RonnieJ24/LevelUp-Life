import UIKit
import SceneKit
import SwiftUI
import GLTFKit2

/// GLTFKit2-based Avatar Renderer
final class GLTFKit2AvatarView: UIView {
    private let sceneView = SCNView()
    private var currentAvatarURL: URL?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
    }
    
    private func setupScene() {
        addSubview(sceneView)
        sceneView.frame = bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        
        // Setup studio lighting
        setupStudioLighting()
    }
    
    func loadAvatar(from glbURL: URL) {
        print("🔍 GLTFKit2: Loading avatar from: \(glbURL.path)")
        currentAvatarURL = glbURL
        
        do {
            let scene = try loadGLBSceneWithGLTFKit2(glbURL)
            sceneView.scene = scene
            print("✅ GLTFKit2: Avatar loaded successfully")
        } catch {
            print("❌ GLTFKit2: Failed to load avatar: \(error.localizedDescription)")
            showErrorCard(error.localizedDescription)
        }
    }
    
    private func loadGLBSceneWithGLTFKit2(_ url: URL) throws -> SCNScene {
        print("🔍 GLTFKit2: Creating GLTFAsset from URL")
        
        let asset = try GLTFAsset(url: url)
        print("✅ GLTFKit2: GLTFAsset created successfully")
        
        let scene = try SCNScene(gltfAsset: asset)
        print("✅ GLTFKit2: Scene built successfully with \(scene.rootNode.childNodes.count) nodes")
        
        // Setup camera for avatar viewing
        setupCamera(for: scene)
        
        return scene
    }
    
    private func setupCamera(for scene: SCNScene) {
        // Remove existing cameras
        scene.rootNode.enumerateChildNodes { node, _ in
            if node.camera != nil {
                node.removeFromParentNode()
            }
        }
        
        // Add new camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 1.5, z: 3.5)
        cameraNode.look(at: SCNVector3(x: 0, y: 1, z: 0))
        scene.rootNode.addChildNode(cameraNode)
        
        print("✅ GLTFKit2: Camera setup complete")
    }
    
    private func setupStudioLighting() {
        // This will be called when we have a scene
        // Studio lighting will be added per scene
    }
    
    private func showErrorCard(_ message: String) {
        print("❌ GLTFKit2 Avatar Load Failed: \(message)")
        
        // Create a simple error scene
        let errorScene = SCNScene()
        
        // Add error text
        let text = SCNText(string: "Avatar Load Failed", extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 0.5)
        text.firstMaterial?.diffuse.contents = UIColor.red
        
        let textNode = SCNNode(geometry: text)
        textNode.position = SCNVector3(x: -1, y: 0, z: 0)
        errorScene.rootNode.addChildNode(textNode)
        
        sceneView.scene = errorScene
    }
    
    func clearAvatar() {
        sceneView.scene = nil
        currentAvatarURL = nil
        print("🧹 GLTFKit2: Avatar cleared")
    }
    
    func getCurrentAvatarURL() -> URL? {
        return currentAvatarURL
    }
}

/// SwiftUI wrapper for GLTFKit2AvatarView
struct GLTFKit2AvatarViewWrapper: UIViewRepresentable {
    @Binding var avatarURL: URL?
    
    func makeUIView(context: Context) -> GLTFKit2AvatarView {
        let view = GLTFKit2AvatarView()
        return view
    }
    
    func updateUIView(_ uiView: GLTFKit2AvatarView, context: Context) {
        if let url = avatarURL {
            uiView.loadAvatar(from: url)
        } else {
            uiView.clearAvatar()
        }
    }
}
