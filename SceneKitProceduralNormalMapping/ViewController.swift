//
//  ViewController.swift
//  SceneKitProceduralNormalMapping
//
//  Created by Simon Gladman on 10/04/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit
import SceneKit
import ModelIO

class ViewController: UIViewController
{
    let sceneKitView: SCNView =
    {
        let scnview = SCNView()
        scnview.scene = SCNScene()

        ViewController.addCameraToScene(scene: scnview.scene!)
        ViewController.addLightsToScene(scene: scnview.scene!)

        return scnview
    }()

    var scene: SCNScene
    {
        return sceneKitView.scene!
    }

    lazy var cube: SCNGeometry =
    {
        [unowned self] in

        return ViewController.addCubeToScene(scene: self.scene)
    }()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        CustomFiltersVendor.registerFilters()

        view.addSubview(sceneKitView)

        let material = ViewController.createMaterial()

        cube.materials = [material]
    }

    // MARK: Static helper functions

    static func createMaterial() -> SCNMaterial
    {
        let material = SCNMaterial()

        let context = CIContext()

        let ciReflectionImage = CIFilter(name: "CISmoothLinearGradient", parameters: nil)!.outputImage!
            .cropped(to: CGRect(x: 0, y: 0, width: 640, height: 640))

        let cgReflectionMap = context.createCGImage(ciReflectionImage,
                                                    from: ciReflectionImage.extent)

        let radialFilter = CIFilter(name: "CIGaussianGradient", parameters: [
            kCIInputCenterKey: CIVector(x: 50, y: 50),
            kCIInputRadiusKey : 45,
            "inputColor0": CIColor(red: 1, green: 1, blue: 1),
            "inputColor1": CIColor(red: 0, green: 0, blue: 0)
            ])

        let ciCirclesImage = radialFilter?
            .outputImage?
            .cropped(to: CGRect(x:0, y: 0, width: 100, height: 100))
            .applyingFilter("CIAffineTile", parameters: [:])
            .cropped(to: CGRect(x:0, y: 0, width: 500, height: 500))
            .applyingFilter("NormalMap")
            .applyingFilter("CIColorControls", parameters: ["inputContrast": 2.5])

        let cgNormalMap = context.createCGImage(ciCirclesImage!,
                                                from: ciCirclesImage!.extent)

        material.lightingModel = SCNMaterial.LightingModel.phong
        material.shininess = 0.1

        material.reflective.contents = cgReflectionMap

        material.diffuse.contents = UIColor.darkGray
        material.specular.contents = UIColor.white

        material.normal.contents = cgNormalMap
        material.normal.intensity = 5.5

        return material
    }


    static func addCameraToScene(scene: SCNScene)
    {
        let camera = SCNCamera()
        camera.fieldOfView = 60

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 20)

        scene.rootNode.addChildNode(cameraNode)
    }

    static func addCubeToScene(scene: SCNScene) -> SCNGeometry
    {
        var cubeNode: SCNNode!
        let cube = SCNBox(width: 6, height: 6, length: 6, chamferRadius: 0.25)
        cube.chamferSegmentCount = 10

        cubeNode = SCNNode(geometry: cube)
        cubeNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cubeNode)

        let action = SCNAction.rotateBy(x: 0.3, y: 0.5, z: 0.7, duration: 2.0)

        cubeNode.runAction(SCNAction.repeatForever(action))

        return cube
    }

    static func addLightsToScene(scene: SCNScene)
    {
        let centreNode = SCNNode()
        centreNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(centreNode)

        addSpotLightToScene(scene: scene, lookAtTarget: centreNode, position: SCNVector3(x: -2.5, y: 12, z: 30))
        addSpotLightToScene(scene: scene, lookAtTarget: centreNode, position: SCNVector3(x: 10, y: -3.5, z: 30))
    }

    static func addSpotLightToScene(scene: SCNScene, lookAtTarget: SCNNode, position: SCNVector3)
    {
        let spotLight = SCNLight()
        spotLight.type = SCNLight.LightType.spot

        spotLight.color = UIColor(white: 0.75, alpha: 1)
        let spotLightNode = SCNNode()
        spotLightNode.light = spotLight
        spotLightNode.position = position

        let constraint = SCNLookAtConstraint(target: lookAtTarget)
        spotLightNode.constraints = [constraint]

        scene.rootNode.addChildNode(spotLightNode)
    }

    override func viewDidLayoutSubviews()
    {
        sceneKitView.frame = view.bounds
    }


}

