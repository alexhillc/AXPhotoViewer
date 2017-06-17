//
//  PhotosViewControllerTransitionAnimator.swift
//  Pods
//
//  Created by Alex Hill on 6/4/17.
//
//

import UIKit
import FLAnimatedImage

@objc enum PhotosViewControllerTransitionAnimatorMode: Int {
    case presenting, dismissing
}

class PhotosViewControllerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    fileprivate let FadeInOutTransitionRatio: Double = 1/3
    
    weak var delegate: PhotosViewControllerTransitionAnimatorDelegate?
    var mode: PhotosViewControllerTransitionAnimatorMode = .presenting
    var transitionInfo: TransitionInfo
    
    init(transitionInfo: TransitionInfo) {
        self.transitionInfo = transitionInfo
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transitionInfo.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.mode == .presenting {
            self.animatePresentation(transitionContext: transitionContext)
        } else if self.mode == .dismissing {
            self.animateDismissal(transitionContext: transitionContext)
        }
    }
    
    fileprivate func animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from),
            let referenceView = self.transitionInfo.referenceView,
            let referenceViewCopy = self.transitionInfo.referenceView?.copy() as? UIImageView else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        to.view.alpha = 0
        to.view.frame = transitionContext.finalFrame(for: to)
        transitionContext.containerView.addSubview(to.view)
        
        let referenceViewFrame = referenceView.frame
        referenceViewCopy.transform = .identity
        referenceViewCopy.frame = transitionContext.containerView.convert(referenceViewFrame, from: referenceView.superview)
        transitionContext.containerView.addSubview(referenceViewCopy)
        
        referenceView.alpha = 0

        let scale = min(to.view.frame.size.width / referenceViewCopy.frame.size.width, to.view.frame.size.height / referenceViewCopy.frame.size.height)
        let scaledSize = CGSize(width: referenceViewCopy.frame.size.width * scale, height: referenceViewCopy.frame.size.height * scale)
        let scaleAnimations = { () in
            referenceViewCopy.frame.size = scaledSize
            referenceViewCopy.center = to.view.center
        }
        
        let scaleCompletion = { [weak self] (_ finished: Bool) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.animationController(uSelf, didFinishAnimatingWith: referenceViewCopy, animatorMode: .presenting)
            
            to.view.alpha = 1
            from.view.alpha = 1
            referenceView.alpha = 1
            referenceViewCopy.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
        
        let fadeAnimations = { () in
            from.view.alpha = 0
        }
        
        transitionContext.containerView.layoutIfNeeded()
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
                       animations: scaleAnimations,
                       completion: scaleCompletion)
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: fadeAnimations)
        
        UIView.animateCornerRadii(withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
                                  to: 0,
                                  views: [referenceViewCopy])
    }
    
    fileprivate func animateDismissal(transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) as? PhotosViewController,
            let imageView = from.currentPhotoViewController?.zoomingImageView.imageView as UIImageView?,
            let referenceView = self.transitionInfo.referenceView else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        to.view.alpha = 0
        to.view.frame = transitionContext.finalFrame(for: to)
        transitionContext.containerView.addSubview(to.view)
        
        from.view.alpha = 1
        from.view.frame = transitionContext.finalFrame(for: from)
        transitionContext.containerView.addSubview(from.view)
        
        let imageViewFrame = imageView.frame
        imageView.transform = .identity
        imageView.frame = transitionContext.containerView.convert(imageViewFrame, from: imageView.superview)
        transitionContext.containerView.addSubview(imageView)
        
        referenceView.alpha = 0
        
        let scaleAnimations = { () in
            imageView.frame = transitionContext.containerView.convert(referenceView.frame, from: referenceView.superview)
        }
        
        let scaleCompletion = { [weak self] (_ finished: Bool) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.animationController(uSelf, didFinishAnimatingWith: imageView, animatorMode: .dismissing)
            
            if let imageView = imageView as? FLAnimatedImageView, let referenceView = referenceView as? FLAnimatedImageView {
                referenceView.syncFrames(with: imageView)
            }
            
            referenceView.alpha = 1
            imageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
        
        let fadeAnimations = { () in
            to.view.alpha = 1
            from.view.alpha = 0
        }
        
        transitionContext.containerView.layoutIfNeeded()
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
                       animations: scaleAnimations,
                       completion: scaleCompletion)
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: fadeAnimations)
        
        UIView.animateCornerRadii(withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
                                  to: referenceView.layer.cornerRadius,
                                  views: [imageView])
    }
    
}

@objc(AXPhotosViewControllerTransitionAnimatorDelegate) protocol PhotosViewControllerTransitionAnimatorDelegate {
    
    @objc(animationController:didFinishAnimatingWithView:animatorMode:)
    func animationController(_ animationController: PhotosViewControllerTransitionAnimator,
                             didFinishAnimatingWith view: UIImageView,
                             animatorMode: PhotosViewControllerTransitionAnimatorMode)
    
}
