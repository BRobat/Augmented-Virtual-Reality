//
//  ViewController.swift
//  AVR
//
//  Created by Tohil on 16/04/2018.
//  Copyright © 2018 Robat. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var sceneView2: ARSCNView!
    
    var targetCreationTime:TimeInterval = 0
    let deletingDistance:Float = 2.0 //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set up SceneView2 (Right Eye)
        sceneView2.scene = scene
        sceneView2.showsStatistics = sceneView.showsStatistics
        sceneView2.isPlaying = true // Turn on isPlaying to ensure this ARSCNView recieves updates.
     
        // Set up gravity
        scene.physicsWorld.gravity = SCNVector3(x: 0.0,y: -0.01,z: 0.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    // UPDATE EVERY FRAME:
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Generate flake every period of time
        if time > targetCreationTime {
            addFlake()
            targetCreationTime = time + 0.02
        }
        cleanUp()
        // Update scenes
        DispatchQueue.main.async {
            self.updateFrame()
        }
    }
    
    func addFlake(){
        // Generate flakes
        // Set shape of a flake
        let flake:SCNGeometry = SCNBox(width: 0.1, height: 0.06, length: 0.01, chamferRadius: 0.1)
        
        // Set flake color
        let color = UIColor.white
        flake.materials.first?.diffuse.contents = color
        
        // Set up starting position
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform

        let randomPositionX = transform.m41 + Float(random(min: -3.0, max: 3.0))
        let randomPositionY = transform.m42 + Float(random(min: -0.0, max: 2.0))
        let randomPositionZ = transform.m43 + Float(random(min: -3.0, max: 3.0))
        
        // Set up flake and it's physical properties
        let flakeNode = SCNNode(geometry: flake)
        flakeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        flakeNode.physicsBody?.isAffectedByGravity = true
        flakeNode.position = SCNVector3(x: Float(randomPositionX), y: Float(randomPositionY),z: Float(randomPositionZ))
        
        // Adding flakes to the scene
        sceneView.scene.rootNode.addChildNode(flakeNode)
    }
    
    func cleanUp () {
        // Deleting every flake which is far enough
        
        print("-")
        
        for node in sceneView.scene.rootNode.childNodes {
            if node.presentation.position.x < -deletingDistance ||
                node.presentation.position.y < -deletingDistance ||
                node.presentation.position.z < -deletingDistance ||
                node.presentation.position.x > deletingDistance ||
                node.presentation.position.y > deletingDistance ||
                node.presentation.position.z > deletingDistance {
                    node.removeFromParentNode()
                    print("clean")
            }
        }
    }
    
    
    func updateFrame() {
        
        // Clone pointOfView for Second View
        let pointOfView : SCNNode = (sceneView.pointOfView?.clone())!
        
        // Determine Adjusted Position for Right Eye
        let orientation : SCNQuaternion = pointOfView.orientation
        let orientationQuaternion : GLKQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        let eyePos : GLKVector3 = GLKVector3Make(0.2, 0.0, 0.0)
        let rotatedEyePos : GLKVector3 = GLKQuaternionRotateVector3(orientationQuaternion, eyePos)
        let rotatedEyePosSCNV : SCNVector3 = SCNVector3Make(rotatedEyePos.x, rotatedEyePos.y, rotatedEyePos.z)
        
        let mag : Float = 0.066 // This is the value for the distance between two pupils (in metres). The Interpupilary Distance (IPD).
        pointOfView.position.x += rotatedEyePosSCNV.x * mag
        pointOfView.position.y += rotatedEyePosSCNV.y * mag
        pointOfView.position.z += rotatedEyePosSCNV.z * mag
        
        // Set PointOfView for SecondView
        sceneView2.pointOfView = pointOfView
        
    }
    
    //
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
}

func +(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
    return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
}
