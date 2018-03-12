//
//  CustomLoadingView.swift
//  AXPhotoViewerExample
//
//  Created by Alex Hill on 7/1/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import AXPhotoViewer
import DRPLoadingSpinner

class CustomLoadingView: AXLoadingView {
    
    fileprivate lazy var _indicatorView = DRPLoadingSpinner()
    override var indicatorView: UIView {
        get {
            return _indicatorView
        }
    }
    
    override func startLoading(initialProgress: CGFloat) {
        if _indicatorView.superview == nil {
            self.addSubview(_indicatorView)
            self.setNeedsLayout()
        }
        
        if !_indicatorView.isAnimating {
            _indicatorView.startAnimating()
        }
    }
    
    override func stopLoading() {
        if _indicatorView.isAnimating {
            _indicatorView.stopAnimating()
        }
    }

}
