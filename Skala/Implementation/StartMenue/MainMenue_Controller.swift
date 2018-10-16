//
//  MainMenueController.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import UIKit

internal final class MainMenue_Controller: UIViewController {
    
    //: Subviews
    private final let manualMeasurementController = ManualMeasurement_Controller.init(nibName: nil, bundle: nil)
    private final let automaticMeasurementController = AutomaticMeasurement_Controller.init(nibName: nil, bundle: nil)
    
    //: GUI-Elements
    private lazy var manualMeasureButton = { () -> MainMenue_ModeButton in
        let button = MainMenue_ModeButton.init(frame: CGRect.init(x: 70, y: 70, width: 150, height: 70)
            , touchesBeganAction: {
            self.present(self.manualMeasurementController, animated: true, completion: {
                print("ManualMeasurement presented")
                return
            })
        })
        button.backgroundColor = UIColor.red
        button.setTitle("Manual", for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 15
        return button
    }()
    
    private lazy var automaticMeasureButton = { () -> MainMenue_ModeButton in
        let button = MainMenue_ModeButton.init(frame: CGRect.init(x: 70, y: 140, width: 150, height: 70)
            , touchesBeganAction: {
                self.present(self.automaticMeasurementController, animated: true, completion: {
                    print("AutomaticMeasurement presented")
                    return
                })
        })
        button.backgroundColor = UIColor.gray
        button.setTitle("Automatic", for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 15
        return button
    }()

    //: Functions
    override final func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        self.manualMeasureButton.alpha = 0.0
        self.automaticMeasureButton.alpha = 0.0
        
        self.view.addSubview(self.manualMeasureButton)
        self.view.addSubview(self.automaticMeasureButton)
        
        UIView.animate(withDuration: 1.0) {
            self.manualMeasureButton.alpha = 1.0
            self.automaticMeasureButton.alpha = 1.0
        }
    }

}
