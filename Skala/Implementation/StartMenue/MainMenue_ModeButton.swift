//
//  MainMenue_ModeButton.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit

internal final class MainMenue_ModeButton: UIButton {
    
    private final let touchesBeganAction: () -> Void
    
    init(frame: CGRect, touchesBeganAction: @escaping () -> Void) {
        self.touchesBeganAction = touchesBeganAction
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override final internal func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesBeganAction()
    }
}
