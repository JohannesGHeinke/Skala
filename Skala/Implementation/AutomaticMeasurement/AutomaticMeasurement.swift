//
//  AutomaticMeasurement.swift
//  Skala
//
//  Created by Johannes Heinke Business on 18.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit
/*
private typealias World = UndirectedGraphSet<SCNNode, Edge>
private typealias WorldBranchWorker = UndirectedGraph<SCNNode, Edge>.BranchWorker

/*
 #############################################################################
 
 #############################################################################
 */

private enum StateKey {
    case walking
    case setting(WorldBranchWorker)
    case measuring
}

private protocol AutomaticMeasurement_State {
    
    /// Called if the State goes to current State
    mutating func appaer() -> StateKey?
    /// Called if the State goes out of current State
    mutating func disappaer()
    
    mutating func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey?
    func handleTouchesMoved(_ touchPoint: CGPoint) -> StateKey?
    func handleTouchesEnded(_ touchPoint: CGPoint) -> StateKey?
    func handleTouchesCancelled(_ touchPoint: CGPoint) -> StateKey?
}

/*
 #############################################################################
 
 #############################################################################
 */

private struct Edge: hasUniqueKey {
    
    fileprivate let line: SCNNode
    fileprivate let textNode: SCNNode
    
    var key: Int {
        return self.line.hash
    }
}

/*
 #############################################################################
 
 #############################################################################
 */

extension SCNNode: hasUniqueKey {
    var key: Int {
        return self.hash
    }
}

//: Walking State
private struct AutomaticMeasurement_WalkingState: AutomaticMeasurement_State {
    
    private let sceneView: ARSCNView
    private let getWorld: (_ world: (World) -> Void) -> Void
    
    init(sceneView: ARSCNView, world: @escaping (_ world: (World) -> Void) -> Void) {
        self.sceneView = sceneView
        self.getWorld = world
    }
    
    fileprivate nonmutating func appaer() -> StateKey? {
        print("Walking")
        return nil
    }
    fileprivate nonmutating func disappaer() {}
    
    fileprivate nonmutating func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey? {
        guard let hittedNode = self.sceneView.hitTest(touchPoint).first?.node, let hittedNodeWorker = { () -> WorldBranchWorker? in
                var result: WorldBranchWorker? = nil
                self.getWorld({ (world) in
                    result = world.getWorker(for: hittedNode)
                })
                return result
            }() else {
            return .measuring
        }
        return .setting(hittedNodeWorker)
    }
    
    fileprivate nonmutating func handleTouchesMoved(_ touchPoint: CGPoint) -> StateKey? { return nil }
    fileprivate nonmutating func handleTouchesEnded(_ touchPoint: CGPoint) -> StateKey? { return nil }
    fileprivate nonmutating func handleTouchesCancelled(_ touchPoint: CGPoint) -> StateKey? { return nil }
}

//: Setting State --> Singleton State
private struct AutomaticMeasurement_SettingState: AutomaticMeasurement_State {
    
    private let changeWorld: (_ world: (inout World) -> Void) -> Void
    private let sceneView: ARSCNView
    private let settingNode: WorldBranchWorker
    
    private nonmutating func getPositionInFront(at touchPosition: CGPoint) -> SCNVector3 {
        let depth = self.sceneView.projectPoint(self.settingNode.branch.position).z
        let locationWithZ = SCNVector3.init(touchPosition.x, touchPosition.y, CGFloat(depth))
        return sceneView.unprojectPoint(locationWithZ)
    }
    
    init(world: @escaping (_ world: (inout World) -> Void) -> Void, sceneView: ARSCNView, settingNode: WorldBranchWorker) {
        self.changeWorld = world
        self.sceneView = sceneView
        self.settingNode = settingNode
    }
    
    fileprivate nonmutating func appaer() -> StateKey? {
        print("Setting")
        return nil }
    fileprivate nonmutating func disappaer() {}
    
    fileprivate nonmutating func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey? { return nil }
    
    fileprivate nonmutating func handleTouchesMoved(_ touchPoint: CGPoint) -> StateKey? {
        //: Later use validation
        
        //: Move the Node
        let nodeMovement = SCNAction.move(to: self.getPositionInFront(at: touchPoint), duration: 0.01)
        self.settingNode.branch.runAction(nodeMovement)
        self.settingNode.replaceConnections { (start, edge, end) -> Edge in
            edge.line.removeFromParentNode()
            let newLine = self.settingNode.branch.createLine(to: end.position)
            sceneView.scene.rootNode.addChildNode(newLine)
            newLine.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            return Edge.init(line: newLine, textNode: edge.textNode)
        }
        
        return nil
    }
    
    fileprivate nonmutating func handleTouchesEnded(_ touchPoint: CGPoint) -> StateKey? { return .walking }
    fileprivate nonmutating func handleTouchesCancelled(_ touchPoint: CGPoint) -> StateKey? { return .walking }
}

//: Measuring State
private final class AutomaticMeasurement_MeasuringState: AutomaticMeasurement_State {
    
    private let changeWorld: (_ world: (inout World) -> Void) -> Void
    private let sceneView: ARSCNView
    private let startNode: SCNNode? = nil
    
    private func createMeasuringPoint(for position: SCNVector3) -> SCNNode {
        let sphereGeo = SCNSphere.init(radius: 0.01)
        sphereGeo.firstMaterial?.diffuse.contents = UIColor.yellow
        let sphereNode = SCNNode.init(geometry: sphereGeo)
        sphereNode.position = position
        return sphereNode
    }
    
    private func createMeasuringLine(from startNode: SCNNode, to endPosition: SCNVector3) -> SCNNode {
        let lineNode = startNode.createLine(to: endPosition)
        lineNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        return lineNode
    }
    
    private func addToRootNode(_ measuringNode: SCNNode) {
        let appearAction = SCNAction.fadeIn(duration: 0.5)
        self.sceneView.scene.rootNode.addChildNode(measuringNode)
        measuringNode.runAction(appearAction)
    }
    
    private nonmutating func getNode(for touchPosition: CGPoint) -> SCNNode? {
        let hitResult = self.sceneView.hitTest(touchPosition, options: nil)
        return hitResult.first?.node
    }
    
    private mutating func handleMeasuringSituation() -> StateKey? {
        guard let startNode = self.startNode else {
            
            //: Initalisiert alles für die Messung
            func initMeasurement(with startNode: SCNNode) {
                //: !!!!! hier noch Textaktualisierung hinzufügen
                self.startNode = startNode
            }
            
            //: Startnode unbekannt --> zunächst diese ermitteln
            guard let knownStartNode = self.getNode(for: self.sceneView.center) else {
                //: neuen Wert über Hittest bestimmen
                guard let startValue = self.sceneView.worldPosition(from: self.sceneView.center)?.position else {
                    //: kein Wert konnte gemessen werden
                    return nil
                }
                let startNode = self.createMeasuringPoint(for: startValue)
                self.addToRootNode(startNode)
                initMeasurement(with: startNode)
                print("1")
                return nil
            }
            initMeasurement(with: knownStartNode)
            print("2")
            return nil
        }
        
        //: Startpunkt bekannt --> Endpunkt ermitteln, zunächst Test auf bekannte Node
        guard let knownEndNode = self.getNode(for: self.sceneView.center) else {
            //: Endpunkt über Hittest finden
            guard let endValue = self.sceneView.worldPosition(from: self.sceneView.center)?.position else {
                //: Kein Wert konnte gemessen werden
                return nil
            }
            
            let endNode = self.createMeasuringPoint(for: endValue)
            let lineNode = startNode.createLine(to: endValue)
            self.changeWorld { (world) in
                world.insertConnection(from: startNode, with: Edge.init(line: lineNode, textNode: SCNNode.init()), to: endNode)
            }
            self.addToRootNode(endNode)
            self.addToRootNode(lineNode)
            print("3")
            return .walking
        }
        
        //: Endnode bekannt
        let lineNode = startNode.createLine(to: knownEndNode.position)
        self.changeWorld { (world) in
            world.insertConnection(from: startNode, with: Edge.init(line: lineNode, textNode: SCNNode.init()), to: knownEndNode)
        }
        self.addToRootNode(lineNode)
        print("4")
        return .walking
    }
    
    init(world: @escaping (_ world: (inout World) -> Void) -> Void, sceneView: ARSCNView) {
        self.changeWorld = world
        self.sceneView = sceneView
    }
    
    fileprivate mutating func appaer() -> StateKey? {
        print("Measuring")
        return self.handleMeasuringSituation()
    }
    fileprivate mutating func disappaer() {
        self.startNode = nil
    }
    
    fileprivate mutating func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey? { return self.handleMeasuringSituation() }
    fileprivate nonmutating func handleTouchesMoved(_ touchPoint: CGPoint) -> StateKey? { return nil }
    fileprivate nonmutating func handleTouchesEnded(_ touchPoint: CGPoint) -> StateKey? { return nil }
    fileprivate nonmutating func handleTouchesCancelled(_ touchPoint: CGPoint) -> StateKey? { return nil }
}

/*
 #############################################################################
 
 #############################################################################
 */

private final class AutomaticMeasurementUI_CancelButton: UIButton {
    
    private final let controller: AutomaticMeasurement_Controller
    
    init(frame: CGRect, controller: AutomaticMeasurement_Controller) {
        self.controller = controller
        super.init(frame: frame)
    }
    
    override fileprivate final func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.controller.dismiss(animated: true) {
            print("Dismissed")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

/*
 #############################################################################
 
 #############################################################################
 */

internal final class AutomaticMeasurement_Controller: UIViewController, ARSCNViewDelegate {
    
    //: State-Pattern
    private final var currentState: (state: AutomaticMeasurement_State, key: StateKey)
    //: constant State
    private final var walkingState: AutomaticMeasurement_WalkingState
    //: mutable State
    private final var measuringState: AutomaticMeasurement_MeasuringState
    
    //: Initialisation
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.world = World.init()
        self.sceneView = ARSCNView.init()
        self.sceneView.automaticallyUpdatesLighting = true
        self.sceneView.autoenablesDefaultLighting = true
        
        self.walkingState = AutomaticMeasurement_WalkingState.init(sceneView: self.sceneView, world: { (_) in
            return
        })
        self.currentState = (self.walkingState, .walking)
        self.measuringState = AutomaticMeasurement_MeasuringState.init(world: { (_) in
            return
        }, sceneView: self.sceneView)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        //: Correct MeasuringState & Correct WalkingState
        self.measuringState = AutomaticMeasurement_MeasuringState.init(world: { (handleWorld) in
            handleWorld(&self.world)
        }, sceneView: self.sceneView)
        self.walkingState = AutomaticMeasurement_WalkingState.init(sceneView: self.sceneView, world: { (handleWorld) in
            handleWorld(self.world)
        })
        
        
        self.sceneView.frame = self.view.frame
        self.sceneView.delegate = self
        self.sceneView.scene = SCNScene.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    //: Manage States -> recursivly
    private final func changeState(to nextState: StateKey) {
        self.currentState.state.disappaer()
        switch self.currentState.key {
        case .measuring:
            self.measuringState = self.currentState.state as! AutomaticMeasurement_MeasuringState
        default:
            break
        }
        
        func _changeState(to state: inout AutomaticMeasurement_State, ifNoChangeIsCalled: (AutomaticMeasurement_State, StateKey)) {
            guard let possibleNextState = state.appaer() else {
                self.currentState = ifNoChangeIsCalled
                return
            }
            self.changeState(to: possibleNextState)
        }
        
        switch nextState {
        case .measuring:
            var tmp = self.measuringState as AutomaticMeasurement_State
            _changeState(to: &tmp, ifNoChangeIsCalled: (self.measuringState, .measuring))
            self.measuringState = tmp as! AutomaticMeasurement_MeasuringState
            
        case .walking:
            var tmp = self.walkingState as AutomaticMeasurement_State
            _changeState(to: &tmp, ifNoChangeIsCalled: (self.walkingState, .walking))
            self.walkingState = tmp as! AutomaticMeasurement_WalkingState
            
        case let .setting(node):
            //: SingletonState
            var settingState = AutomaticMeasurement_SettingState.init(world: { (handleWorld) in
                handleWorld(&self.world)
            }, sceneView: self.sceneView, settingNode: node) as AutomaticMeasurement_State
            _changeState(to: &settingState, ifNoChangeIsCalled: (settingState, .setting(node)))
        }
    }
    
    //: World Model
    private final var world: World
    
    //: ARKit Setup
    private final let sceneView: ARSCNView
    
    //: UI-Elements
    private lazy var cancelButton = { () -> AutomaticMeasurementUI_CancelButton in
        let button = AutomaticMeasurementUI_CancelButton.init(frame: CGRect.init(x: 70, y: 70, width: 70, height: 70)
            , controller: self)
        button.backgroundColor = UIColor.gray
        return button
    }()
    
    //: ViewController Functions
    override internal final func viewDidLoad() {
        super.viewDidLoad()
        
        //: Init UI
        self.view.addSubview(self.sceneView)
        self.view.addSubview(self.cancelButton)
    }
    
    override internal final func viewWillAppear(_ animated: Bool) {
        self.sceneView.session.run(ARWorldTrackingConfiguration.init())
        super.viewWillAppear(animated)
    }
    
    override internal final func viewWillDisappear(_ animated: Bool) {
        self.sceneView.session.pause()
        super.viewWillDisappear(animated)
    }
    
    override internal final func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPosition = touch.location(in: self.view)
        guard let newState = self.currentState.state.handleTouchesBegan(touchPosition) else { return }
        self.changeState(to: newState)
    }
    
    override internal final func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPosition = touch.location(in: self.view)
        guard let newState = self.currentState.state.handleTouchesMoved(touchPosition) else { return }
        self.changeState(to: newState)
    }
    
    override internal final func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPosition = touch.location(in: self.view)
        guard let newState = self.currentState.state.handleTouchesCancelled(touchPosition) else { return }
        self.changeState(to: newState)
    }
    
    override internal final func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPosition = touch.location(in: self.view)
        guard let newState = self.currentState.state.handleTouchesEnded(touchPosition) else { return }
        self.changeState(to: newState)
    }
}
*/
