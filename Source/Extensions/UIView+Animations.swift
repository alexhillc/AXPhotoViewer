//
//  UIView+Animations.swift
//  Pods
//
//  Created by Alex Hill on 6/11/17.
//
//

import UIKit

extension UIView {
    
    class func springyAnimate(withDuration duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
            animations: animations,
            completion: completion
        )
    }
    
    class func animateCornerRadii(withDuration duration: TimeInterval, to value: CGFloat, views: [UIView], completion: ((Bool) -> Void)? = nil) {
        assert(views.count > 0, "Must call `animateCornerRadii:duration:value:views:completion:` with at least 1 view.")
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion?(true)
        }
        
        for view in views {
            view.layer.masksToBounds = true
            
            let animation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            animation.fromValue = view.layer.cornerRadius
            animation.toValue = value
            animation.duration = duration
            
            view.layer.add(animation, forKey: "CornerRadiusAnim")
            view.layer.cornerRadius = value
        }
        
        CATransaction.commit()
    }
    
}
