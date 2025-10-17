import UIKit
import SceneKit
import SwiftUI
import GLTFKit2
import simd

/// GLTFKit2-based Avatar Renderer - Avatar Workshop v1.1
final class GLTFKit2AvatarView: UIView {
    private let sceneView = SCNView()
    var currentAvatarURL: URL?
    private var scene: SCNScene?
    private var cameraNode: SCNNode!
    private var orbitNode: SCNNode!
    private var avatarRootNode: SCNNode?
    
    // Lighting nodes
    private var keyLightNode: SCNNode!
    private var fillLightNode: SCNNode!
    private var rimLightNode: SCNNode!
    private var floorNode: SCNNode!
    
    // Gesture recognizers
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    // Settings
    private var lightingPreset: String = "studio"
    private var backgroundPreset: String = "black"
    private var scaleMultiplier: Float = 1.0
    private var isIdleRotating = false
    private var idleRotationTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScene()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
        setupGestures()
    }
    
    deinit {
        idleRotationTimer?.invalidate()
    }

    private func setupScene() {
        addSubview(sceneView)
        sceneView.frame = bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        sceneView.allowsCameraControl = false // We'll handle gestures manually
        sceneView.autoenablesDefaultLighting = false // We'll set up custom lighting
        sceneView.antialiasingMode = .multisampling4X
        
        // Create scene
        scene = SCNScene()
        sceneView.scene = scene
        
        setupCamera()
        setupLighting()
        setupGround()
    }
    
    private func setupCamera() {
        // Create orbit container
        orbitNode = SCNNode()
        scene?.rootNode.addChildNode(orbitNode)
        
        // Create camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 1.5, 3.5)
        cameraNode.look(at: SCNVector3(0, 1.5, 0))
        
        // Add slight tilt to orbit
        orbitNode.eulerAngles.x = -.pi/12
        
        orbitNode.addChildNode(cameraNode)
    }
    
    private func setupLighting() {
        // Environment lighting
        scene?.lightingEnvironment.intensity = 1.2
        
        // Key light
        let keyLight = SCNLight()
        keyLight.type = .omni
        keyLight.intensity = 1300
        keyLight.castsShadow = true
        keyLight.shadowMode = .deferred
        keyLight.shadowRadius = 8
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.6)
        
        keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.position = SCNVector3(1.2, 2.2, 1.8)
        scene?.rootNode.addChildNode(keyLightNode)
        
        // Fill light
        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.intensity = 600
        
        fillLightNode = SCNNode()
        fillLightNode.light = fillLight
        fillLightNode.position = SCNVector3(-1.6, 1.6, 1.4)
        scene?.rootNode.addChildNode(fillLightNode)
        
        // Rim light
        let rimLight = SCNLight()
        rimLight.type = .omni
        rimLight.intensity = 900
        
        rimLightNode = SCNNode()
        rimLightNode.light = rimLight
        rimLightNode.position = SCNVector3(0.0, 2.2, -1.6)
        scene?.rootNode.addChildNode(rimLightNode)
    }
    
    private func setupGround() {
        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor.black
        floor.firstMaterial?.colorBufferWriteMask = []
        floor.firstMaterial?.writesToDepthBuffer = true
        
        floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, 0, 0)
        scene?.rootNode.addChildNode(floorNode)
    }
    
    private func setupGestures() {
        // Pan gesture for orbit
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        addGestureRecognizer(panGesture)
        
        // Two-finger pan for vertical orbit
        let twoFingerPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        addGestureRecognizer(twoFingerPan)
        
        // Pinch gesture for zoom
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        // Tap gesture to toggle idle rotation
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    func loadAvatar(from glbURL: URL) {
        self.currentAvatarURL = glbURL
        do {
            let scene = try loadGLBSceneWithGLTFKit2(glbURL)
            avatarRootNode = scene.rootNode.childNodes.first
            if let avatarNode = avatarRootNode {
                self.scene?.rootNode.addChildNode(avatarNode)
                autoFitAvatar(avatarNode)
                applyScaleMultiplier(scaleMultiplier)
                applyLightingPreset(lightingPreset)
                applyBackgroundPreset(backgroundPreset)
            }
        } catch {
            showErrorCard(error.localizedDescription)
        }
    }
    
    private func loadGLBSceneWithGLTFKit2(_ url: URL) throws -> SCNScene {
        print("🔍 GLTFKit2: Creating GLTFAsset from URL")
        
        let asset = try GLTFAsset(url: url)
        print("✅ GLTFKit2: GLTFAsset created successfully")
        
        let scene = try SCNScene(gltfAsset: asset)
        print("✅ GLTFKit2: Scene built successfully with \(scene.rootNode.childNodes.count) nodes")
        
        return scene
    }
    
    // MARK: - Auto-fit Avatar
    
    private func autoFitAvatar(_ root: SCNNode) {
        // Simple auto-fit without complex bounding box calculations
        // Center the avatar and set up camera positioning
        
        // Reset position to center
        root.position = SCNVector3(0, 0, 0)
        
        // Set up camera for good viewing angle
        cameraNode.position = SCNVector3(0, 1.5, 3.5)
        cameraNode.look(at: SCNVector3(0, 1.5, 0))
        
        print("🎯 Avatar Workshop: Auto-fitted avatar with standard positioning")
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        orbitNode.eulerAngles.y -= Float(translation.x) * 0.005
        gesture.setTranslation(.zero, in: self)
        
        // Stop idle rotation during interaction
        stopIdleRotation()
    }
    
    @objc private func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        orbitNode.eulerAngles.x = max(-.pi/3, min(-0.05, orbitNode.eulerAngles.x - Float(translation.y) * 0.005))
        gesture.setTranslation(.zero, in: self)
        
        // Stop idle rotation during interaction
        stopIdleRotation()
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let z = cameraNode.position.z
        let newZ = CGFloat(z) / gesture.scale
        cameraNode.position.z = SCNFloat(clamp(newZ, 0.8, 4.0))
        gesture.scale = 1
        
        // Stop idle rotation during interaction
        stopIdleRotation()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        toggleIdleRotation()
    }
    
    private func clamp<T: Comparable>(_ x: T, _ a: T, _ b: T) -> T {
        return max(a, min(b, x))
    }
    
    // MARK: - Idle Rotation
    
    private func startIdleRotation() {
        guard !isIdleRotating else { return }
        isIdleRotating = true
        
        idleRotationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.orbitNode.eulerAngles.y += 0.01
        }
    }
    
    private func stopIdleRotation() {
        isIdleRotating = false
        idleRotationTimer?.invalidate()
        idleRotationTimer = nil
    }
    
    private func toggleIdleRotation() {
        if isIdleRotating {
            stopIdleRotation()
        } else {
            startIdleRotation()
        }
    }
    
    // MARK: - Lighting Presets
    
    func applyLightingPreset(_ name: String) {
        lightingPreset = name
        
        switch name {
        case "daylight":
            keyLightNode.light?.intensity = 1200
            fillLightNode.light?.intensity = 800
            rimLightNode.light?.intensity = 600
            scene?.lightingEnvironment.intensity = 1.0
            sceneView.backgroundColor = UIColor(hue: 0.61, saturation: 0.12, brightness: 0.08, alpha: 1)
            
        case "cyber":
            keyLightNode.light?.intensity = 1600
            fillLightNode.light?.intensity = 200
            rimLightNode.light?.intensity = 1400
            scene?.lightingEnvironment.intensity = 1.6
            sceneView.backgroundColor = .black
            
        default: // studio
            keyLightNode.light?.intensity = 1300
            fillLightNode.light?.intensity = 600
            rimLightNode.light?.intensity = 900
            scene?.lightingEnvironment.intensity = 1.2
            sceneView.backgroundColor = .black
        }
        
        // Haptic feedback
        HapticManager.shared.lightTap()
        
        print("💡 Avatar Workshop: Applied lighting preset: \(name)")
    }
    
    func applyBackgroundPreset(_ name: String) {
        backgroundPreset = name
        
        switch name {
        case "gradient":
            // Create gradient background
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.systemPurple.cgColor,
                UIColor.systemBlue.cgColor
            ]
            gradientLayer.frame = bounds
            sceneView.backgroundColor = .clear
            layer.insertSublayer(gradientLayer, at: 0)
            
        default: // black
            sceneView.backgroundColor = .black
            layer.sublayers?.removeAll { $0 is CAGradientLayer }
        }
        
        print("🎨 Avatar Workshop: Applied background preset: \(name)")
    }
    
    func applyScaleMultiplier(_ scale: Float) {
        scaleMultiplier = scale
        avatarRootNode?.scale = SCNVector3(scale, scale, scale)
        
        // Haptic feedback
        HapticManager.shared.lightTap()
        
        print("📏 Avatar Workshop: Applied scale multiplier: \(scale)")
    }
    
    // MARK: - Performance & Lifecycle
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        sceneView.isPlaying = (window != nil)
        
        if window != nil {
            startIdleRotation()
        } else {
            stopIdleRotation()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient background if needed
        if backgroundPreset == "gradient" {
            layer.sublayers?.forEach { layer in
                if layer is CAGradientLayer {
                    layer.frame = bounds
                }
            }
        }
    }
    
    private func showErrorCard(_ message: String) {
        print("❌ Avatar Workshop: \(message)")
        // Keep existing telemetry + ErrorCard UI if available
    }
}

// MARK: - SwiftUI Wrapper

struct GLTFKit2AvatarViewWrapper: UIViewRepresentable {
    var avatarURL: URL?
    @Binding var lightingPreset: String
    @Binding var backgroundPreset: String
    @Binding var scaleMultiplier: Float
    
    func makeUIView(context: Context) -> GLTFKit2AvatarView {
        let view = GLTFKit2AvatarView()
        if let url = avatarURL {
            view.loadAvatar(from: url)
        }
        return view
    }

    func updateUIView(_ uiView: GLTFKit2AvatarView, context: Context) {
        if uiView.currentAvatarURL != avatarURL, let url = avatarURL {
            uiView.loadAvatar(from: url)
        }
        
        // Apply settings changes
        uiView.applyLightingPreset(lightingPreset)
        uiView.applyBackgroundPreset(backgroundPreset)
        uiView.applyScaleMultiplier(scaleMultiplier)
    }
}