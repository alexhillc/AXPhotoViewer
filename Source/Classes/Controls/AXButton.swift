//
//  AXButton.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 3/11/18.
//

import UIKit

#if os(iOS)
import AXStateButton
@objc open class AXButton: StateButton {
    
    public init() {
        super.init(frame: .zero)
        self.controlStateAnimationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.controlStateAnimationDuration = 0.1
        self.setBorderWidth(1.0, for: .normal)
        self.setBorderColor(.white, for: .normal)
        self.setAlpha(1.0, for: .normal)
        self.setAlpha(0.3, for: .highlighted)
        self.setTransformScale(1.0, for: .normal)
        self.setTransformScale(0.95, for: .highlighted)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
#endif
