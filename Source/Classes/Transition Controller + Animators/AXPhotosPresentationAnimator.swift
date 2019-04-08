//
//  AXPhotosPresentationAnimator.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/5/18.
//

import UIKit

class AXPhotosPresentationAnimator: AXPhotosTransitionAnimator {
    
    // MARK: - UIViewControllerAnimatedTransitioning    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from),
            let startingView = self.transitionInfo.startingView else {
                assertionFailure("Unable to resolve some necessary properties in order to transition. This should never happen.")
                return
        }
        
        let fadeView = self.transitionInfo.fadingBackdropView()
        fadeView.alpha = 0
        fadeView.frame = transitionContext.finalFrame(for: to)
        transitionContext.containerView.addSubview(fadeView)
        self.fadeView = fadeView
        
        to.view.alpha = 0
        to.view.frame = transitionContext.finalFrame(for: to)
        transitionContext.containerView.addSubview(to.view)
        transitionContext.containerView.layoutIfNeeded()
        
        let startingViewContainer = AXImageViewTransitionContainer(imageView: startingView.ax_copy())
        startingViewContainer.transform = from.view.transform
        startingViewContainer.center = transitionContext.containerView.convert(
            startingView.center,
            from: startingView.superview
        )
        transitionContext.containerView.addSubview(startingViewContainer)
        startingViewContainer.layoutIfNeeded()
        
        startingView.alpha = 0
        
        var imageAspectRatio: CGFloat = 1
        if let image = startingViewContainer.imageView.image {
            imageAspectRatio = image.size.width / image.size.height
        }
        
        let startingViewAspectRatio = startingView.bounds.size.width / startingView.bounds.size.height
        var aspectRatioAdjustedSize = startingView.bounds.size
        if abs(startingViewAspectRatio - imageAspectRatio) > .ulpOfOne {
            aspectRatioAdjustedSize.width = aspectRatioAdjustedSize.height * imageAspectRatio
        }
        
        let scale = min(
            to.view.frame.size.width / aspectRatioAdjustedSize.width,
            to.view.frame.size.height / aspectRatioAdjustedSize.height
        )
        let scaledSize = CGSize(
            width: aspectRatioAdjustedSize.width * scale,
            height: aspectRatioAdjustedSize.height * scale
        )
        let scaleAnimations = { () in
            startingViewContainer.transform = .identity
            startingViewContainer.frame.size = scaledSize
            startingViewContainer.center = to.view.center
            startingViewContainer.contentMode = .scaleAspectFit
            startingViewContainer.layoutIfNeeded()
        }
        
        let scaleCompletion = { [weak self] (_ finished: Bool) in
            guard let `self` = self else { return }
            
            self.delegate?.transitionAnimator(self, didCompletePresentationWith: startingViewContainer.imageView)
            
            to.view.alpha = 1
            startingView.alpha = 1
            startingViewContainer.removeFromSuperview()
            self.fadeView?.removeFromSuperview()
            self.fadeView = nil
            transitionContext.completeTransition(true)
        }
        
        let fadeAnimations: () -> Void = { [weak self] in
            self?.fadeView?.alpha = 1
        }
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: self.transitionInfo.presentationSpringDampingRatio,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
            animations: scaleAnimations,
            completion: scaleCompletion
        )
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext) * self.fadeInOutTransitionRatio,
            delay: 0,
            options: [.curveEaseInOut],
            animations: fadeAnimations
        )
        
        UIView.animateCornerRadii(
            withDuration: self.transitionDuration(using: transitionContext) * self.fadeInOutTransitionRatio,
            to: 0,
            views: [startingViewContainer]
        )
    }

}
