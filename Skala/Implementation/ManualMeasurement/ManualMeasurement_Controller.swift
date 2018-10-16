//
//  ManualMeasurementController.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit
import ARKit

internal final class ManualMeasurement_Controller: UIViewController, ARSCNViewDelegate {
    
    //: Init
    override final internal func viewDidLoad() {
        super.viewDidLoad()
        print("ManualMeasurement")
        
        //: Init State Pattern
        _ = self.walkingState.register(controller: self)
        _ = self.measurementState.register(controller: self)
        
        //: Init GUI
        self.cancelButton.alpha = 0.0
        self.tapGestureView.alpha = 0.0
        self.resultLabel.alpha = 0.0
        self.sceneView.alpha = 0.0
        
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.tapGestureView)
        self.view.addSubview(self.resultLabel)
        self.view.addSubview(self.sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self._currentState = self.walkingState
        
        UIView.animate(withDuration: 0.5) {
            self.cancelButton.alpha = 1.0
            self.tapGestureView.alpha = 1.0
            self.resultLabel.alpha = 0.4
        }
    }
    
    override final func viewWillDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.cancelButton.alpha = 0.0
            self.tapGestureView.alpha = 0.0
            self.resultLabel.alpha = 0.0
        }
    }
    
    //: AR-Elements
    internal lazy var sceneView = { () -> ARSCNView in
        let sceneView = ARSCNView.init(frame: self.view.frame)
        sceneView.delegate = self
        let scene = SCNScene.init()
        sceneView.scene = scene
        sceneView.isHidden = true
        
        let config = ARWorldTrackingConfiguration.init()
        sceneView.session.run(config)
        return sceneView
    }()
    
    //: GUI-Elements
    internal lazy var cancelButton = { () -> ManualMeasurementUI_CancelButton in
        let button = ManualMeasurementUI_CancelButton.init(frame: CGRect.init(x: 70, y: 70, width: 150, height: 70)
            , controller: self)
        button.backgroundColor = UIColor.orange
        button.setTitle("Cancel", for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 15
        return button
    }()
    
    internal lazy var tapGestureView = { () -> ManualMeasurementUI_TapGestureView in
        let tapGestureView = ManualMeasurementUI_TapGestureView.init(frame: CGRect.init(x: 70, y: 210, width: 1500, height: 70)
            , controller: self)
        tapGestureView.backgroundColor = UIColor.green
        return tapGestureView
    }()
    
    internal lazy var resultLabel = { () -> ManualMeasurementUI_ResultLabel in
        let label = ManualMeasurementUI_ResultLabel.init(frame: CGRect.init(x: 70, y: 140, width: 150, height: 70)
            , controller: self)
        label.backgroundColor = UIColor.purple
        return label
    }()
    
    //: StatePattern
    private final var _currentState: ManualMeasurement_GeneralState = ManualMeasurement_WalkingState.init()
    
    internal final let walkingState = ManualMeasurement_WalkingState.init()
    internal final let measurementState = ManualMeasurement_MeasurementState.init()
    
    internal final var currentState: ManualMeasurement_GeneralState {
        get {
            return self._currentState
        }
        
        set(newState) {
            self._currentState.disappaerState()
            self._currentState = newState
            self._currentState.appaerState()
        }
    }
    
}
