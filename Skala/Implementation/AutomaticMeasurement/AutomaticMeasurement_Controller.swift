//
//  AutomaticMeasurementController.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit
//: Verbesserung alles (GUI) in einem File und fileprivate nutzen
internal final class AutomaticMeasurement_Controller: UIViewController {
    
    private final let states: UnsafeMutablePointer<AutomaticMeasurement_State>
    
    private final var currentStateKey = StateKey.walking
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.states = .allocate(capacity: 3)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.states.initialize(to: AutomaticMeasurement_WalkingState.init(handler: self))
        self.states.advanced(by: 1).initialize(to: AutomaticMeasurement_SettingState.init(handler: self))
        self.states.advanced(by: 2).initialize(to: AutomaticMeasurement_MeasuringState.init(handler: self))
    }
    
    //: Recursive Appearance
    private final func changeState(to nextState: StateKey) {
        self.states[self.currentStateKey.rawValue].disappaer()
        self.currentStateKey = nextState
        guard let possibleNextState = self.states[self.currentStateKey.rawValue].appaer() else {
            return
        }
        self.changeState(to: possibleNextState)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    internal enum StateKey: Int {
        case walking = 0
        case setting = 1
        case measuring = 2
    }
    
    //: ViewController Functions
    override final internal func viewDidLoad() {
        super.viewDidLoad()
        print("AutomaticMeasurement")
        
        //: Init GUI
        self.cancelButton.alpha = 0.0
        self.view.addSubview(self.cancelButton)
    }
    
    override final internal func viewWillAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.5) {
            self.cancelButton.alpha = 1.0
        }
    }
    
    override final internal func viewWillDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.cancelButton.alpha = 0.0
        }
    }
    
    
    override final internal func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let nextState = self.states[self.currentStateKey.rawValue].handleTouchesBegan(touches, with: event) else {
            return
        }
        self.changeState(to: nextState)
    }
    
    override final internal func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let nextState = self.states[self.currentStateKey.rawValue].handleTouchesMoved(touches, with: event) else {
            return
        }
        self.changeState(to: nextState)
    }
    
    override final internal func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let nextState = self.states[self.currentStateKey.rawValue].handleTouchesEnded() else {
            return
        }
        self.changeState(to: nextState)
    }
    
    override final internal func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let nextState = self.states[self.currentStateKey.rawValue].handleTouchesCancelled() else {
            return
        }
        self.changeState(to: nextState)
    }
    
    //: GUI-Elements
    internal lazy var cancelButton = { () -> AutomaticMeasurementUI_CancelButton in
        let button = AutomaticMeasurementUI_CancelButton.init(frame: CGRect.init(x: 70, y: 70, width: 70, height: 70)
            , controller: self)
        button.backgroundColor = UIColor.gray
        return button
    }()
}
