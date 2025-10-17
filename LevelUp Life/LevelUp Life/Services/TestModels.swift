import Foundation
import SceneKit

/// Test Models for smoke testing
struct TestModels {
    
    /// Load a local USDZ for smoke testing
    /// This creates a simple procedural robot to test our SceneKit setup
    static func loadLocalUSDZ() -> SCNScene {
        let scene = SCNScene()
        
        // Create a simple robot
        let robot = createSimpleRobot()
        scene.rootNode.addChildNode(robot)
        
        // Setup lighting
        setupSceneLighting(scene)
        
        return scene
    }
    
    private static func createSimpleRobot() -> SCNNode {
        let robot = SCNNode()
        
        // Body
        let body = SCNBox(width: 0.8, height: 1.2, length: 0.4, chamferRadius: 0.1)
        body.firstMaterial?.diffuse.contents = UIColor.systemBlue
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.6, 0)
        robot.addChildNode(bodyNode)
        
        // Head
        let head = SCNSphere(radius: 0.3)
        head.firstMaterial?.diffuse.contents = UIColor.systemGray
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.5, 0)
        robot.addChildNode(headNode)
        
        // Eyes
        let eyeGeometry = SCNSphere(radius: 0.05)
        eyeGeometry.firstMaterial?.diffuse.contents = UIColor.red
        
        let leftEye = SCNNode(geometry: eyeGeometry)
        leftEye.position = SCNVector3(-0.1, 1.6, 0.25)
        robot.addChildNode(leftEye)
        
        let rightEye = SCNNode(geometry: eyeGeometry)
        rightEye.position = SCNVector3(0.1, 1.6, 0.25)
        robot.addChildNode(rightEye)
        
        // Arms
        let armGeometry = SCNBox(width: 0.2, height: 0.8, length: 0.2, chamferRadius: 0.05)
        armGeometry.firstMaterial?.diffuse.contents = UIColor.systemGray
        
        let leftArm = SCNNode(geometry: armGeometry)
        leftArm.position = SCNVector3(-0.5, 0.4, 0)
        robot.addChildNode(leftArm)
        
        let rightArm = SCNNode(geometry: armGeometry)
        rightArm.position = SCNVector3(0.5, 0.4, 0)
        robot.addChildNode(rightArm)
        
        // Legs
        let legGeometry = SCNBox(width: 0.25, height: 0.8, length: 0.25, chamferRadius: 0.05)
        legGeometry.firstMaterial?.diffuse.contents = UIColor.systemGray
        
        let leftLeg = SCNNode(geometry: legGeometry)
        leftLeg.position = SCNVector3(-0.2, -0.4, 0)
        robot.addChildNode(leftLeg)
        
        let rightLeg = SCNNode(geometry: legGeometry)
        rightLeg.position = SCNVector3(0.2, -0.4, 0)
        robot.addChildNode(rightLeg)
        
        return robot
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
    }
}