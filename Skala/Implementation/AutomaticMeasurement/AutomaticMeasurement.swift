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
 #############################################################################
 
 #############################################################################
 */

private enum StateKey {
    case walking
    case setting(SCNNode)
    case measuring
}

private protocol AutomaticMeasurement_State {
    
    /// Called if the State goes to current State
    func appaer() -> StateKey?
    /// Called if the State goes out of current State
    func disappaer()
    
    func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey?
    func handleTouchesMoved(_ touchPoint: CGPoint) -> StateKey?
    func handleTouchesEnded(_ touchPoint: CGPoint) -> StateKey?
    func handleTouchesCancelled(_ touchPoint: CGPoint) -> StateKey?
}

/*
 #############################################################################
 
 #############################################################################
 */

private typealias World = UndirectedGraphSet<SCNNode, SCNNode>

extension SCNNode: hasUniqueKey {
    var key: Int {
        return self.hash
    }
}

//: Walking State
private struct AutomaticMeasurement_WalkingState: AutomaticMeasurement_State {
    
    private let sceneView: ARSCNView
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    fileprivate nonmutating func appaer() -> StateKey? { return nil }
    fileprivate nonmutating func disappaer() {}
    
    fileprivate nonmutating func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey? {
        guard let hittedNode = self.sceneView.hitTest(touchPoint).first?.node else {
            return .measuring
        }
        return .setting(hittedNode)
    }
    
    fileprivate nonmutating func handleTouchesMoved(_ touchPoint: CGPoint) -> StateKey? { return nil }
    fileprivate nonmutating func handleTouchesEnded(_ touchPoint: CGPoint) -> StateKey? { return nil }
    fileprivate nonmutating func handleTouchesCancelled(_ touchPoint: CGPoint) -> StateKey? { return nil }
}

//: Setting State
private struct AutomaticMeasurement_SettingState: AutomaticMeasurement_State {
    
    private let changeWorld: (_ world: (inout World) -> Void) -> Void
    private let sceneView: ARSCNView
    private let settingNode: SCNNode
    
    init(world: @escaping (_ world: (inout World) -> Void) -> Void, sceneView: ARSCNView, settingNode: SCNNode) {
        self.changeWorld = world
        self.sceneView = sceneView
        self.settingNode = settingNode
    }
    
    fileprivate nonmutating func appaer() -> StateKey? { return nil }
    fileprivate nonmutating func disappaer() {}
    
    fileprivate nonmutating func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey? { return .measuring }
    fileprivate nonmutating func handleTouchesMoved(_ touchPoint: CGPoint) -> StateKey? { return nil }
    fileprivate nonmutating func handleTouchesEnded(_ touchPoint: CGPoint) -> StateKey? { return .walking }
    fileprivate nonmutating func handleTouchesCancelled(_ touchPoint: CGPoint) -> StateKey? { return .walking }
}

//: Measuring State
private struct AutomaticMeasurement_MeasuringState: AutomaticMeasurement_State {
    
    private let changeWorld: (_ world: (inout World) -> Void) -> Void
    
    init(world: @escaping (_ world: (inout World) -> Void) -> Void) {
        self.changeWorld = world
    }
    
    fileprivate nonmutating func appaer() -> StateKey? { return nil }
    fileprivate nonmutating func disappaer() {}
    
    fileprivate nonmutating func handleTouchesBegan(_ touchPoint: CGPoint) -> StateKey? { return nil }
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
    private final let walkingState: AutomaticMeasurement_WalkingState
    //: mutable State
    private final var measuringState: AutomaticMeasurement_MeasuringState
    
    //: Initialisation
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.world = World.init()
        self.sceneView = ARSCNView.init()
        
        self.walkingState = AutomaticMeasurement_WalkingState.init(sceneView: self.sceneView)
        self.currentState = (self.walkingState, .walking)
        self.measuringState = AutomaticMeasurement_MeasuringState.init(world: { (handleWorld) in
            //: dead initialisiation
            var world = World.init()
            handleWorld(&world)
        })
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        //: Correct MeasuringState
        self.measuringState = AutomaticMeasurement_MeasuringState.init(world: { (handleWorld) in
            handleWorld(&self.world)
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
            return
        }
        
        func _changeState(to state: AutomaticMeasurement_State, ifNoChangeIsCalled: (AutomaticMeasurement_State, StateKey)) {
            guard let possibleNextState = state.appaer() else {
                self.currentState = ifNoChangeIsCalled
                return
            }
            self.changeState(to: possibleNextState)
        }
        
        switch nextState {
        case .measuring:
            _changeState(to: self.measuringState, ifNoChangeIsCalled: (self.measuringState, .measuring))
            
        case .walking:
            _changeState(to: self.walkingState, ifNoChangeIsCalled: (self.walkingState, .walking))
            
        case let .setting(node):
            //: SingletonState
            let settingState = AutomaticMeasurement_SettingState.init(world: { (handleWorld) in
                handleWorld(&self.world)
            }, sceneView: self.sceneView, settingNode: node)
            _changeState(to: settingState, ifNoChangeIsCalled: (settingState, .setting(node)))
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
}
