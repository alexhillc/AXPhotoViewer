//
//  PhotosViewControllerTransitionController.swift
//  Pods
//
//  Created by Alex Hill on 6/4/17.
//
//

import UIKit
import FLAnimatedImage

@objc enum PhotosViewControllerTransitionControllerMode: Int {
    case presenting, dismissing
}

class PhotosViewControllerTransitionController: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning, UIGestureRecognizerDelegate {
    
    fileprivate let FadeInOutTransitionRatio: Double = 1/3
    
    weak var delegate: PhotosViewControllerTransitionControllerDelegate?
    var mode: PhotosViewControllerTransitionControllerMode = .presenting
    var transitionInfo: TransitionInfo
    
    weak var photosViewController: PhotosViewController?
    
    /// The threshold at which the interactive controller will dismiss upon end touches.
    fileprivate var DismissalPercentThreshold: CGFloat = 0.14
    
    // Interactive dismissal transition tracking
    fileprivate var dismissalPercent: CGFloat = 0
    fileprivate var directionalDismissalPercent: CGFloat = 0
    fileprivate var dismissalVelocityY: CGFloat = 1
    fileprivate var completeInteractiveDismissal = false
    
    weak var dismissalTransitionContext: UIViewControllerContextTransitioning?
    
    weak fileprivate var imageView: UIImageView?
    fileprivate var imageViewInitialOriginY: CGFloat = 0
    fileprivate var imageViewOriginalFrame: CGRect = .zero
    fileprivate var imageViewOriginalSuperview: UIView?
    
    weak fileprivate var overlayView: OverlayView?
    fileprivate var navigationBarInitialOriginY: CGFloat = 0
    fileprivate var navigationBarUnderlayInitialOriginY: CGFloat = 0
    fileprivate var captionViewInitialOriginY: CGFloat = 0
    fileprivate var overlayViewOriginalFrame: CGRect = .zero
    fileprivate var overlayViewOriginalSuperview: UIView?
    
    var supportsContextualPresentation: Bool {
        get {
            guard let photosVC = self.photosViewController else {
                return false
            }
            
            return self.canPerformContextualAnimation(using: self.transitionInfo.startingView, in: photosVC.view)
        }
    }
    
    var supportsContextualDismissal: Bool {
        get {
            guard let photosVC = self.photosViewController else {
                return false
            }
            
            return self.canPerformContextualAnimation(using: self.transitionInfo.endingView, in: photosVC.view)
        }
    }
    
    var supportsInteractiveDismissal: Bool {
        get {
            return self.transitionInfo.interactiveDismissalEnabled
        }
    }
    
    init(photosViewController: PhotosViewController, transitionInfo: TransitionInfo) {
        self.photosViewController = photosViewController
        self.transitionInfo = transitionInfo
        
        super.init()
        
        if transitionInfo.interactiveDismissalEnabled {
            self.attach(to: photosViewController)
        }
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
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
        guard let to = transitionContext.viewController(forKey: .to) as? PhotosViewController,
            let from = transitionContext.viewController(forKey: .from),
            let referenceView = self.transitionInfo.startingView,
            let referenceViewCopy = self.transitionInfo.startingView?.copy() as? UIImageView else {
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
            
            uSelf.delegate?.transitionController(uSelf, didFinishAnimatingWith: referenceViewCopy, transitionControllerMode: .presenting)
            
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
    
    fileprivate func animateDismissal(transitionContext: UIViewControllerContextTransitioning, startinVelocity: CGFloat? = nil) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) as? PhotosViewController,
            let imageView = from.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        let continuingFromInteraction = (transitionContext.isInteractive)
        let usingContextualAnimation = self.canPerformContextualAnimation(using: transitionInfo.endingView, in: transitionContext.containerView)
        
        if continuingFromInteraction {
            let imageViewFrame = imageView.frame
            imageView.transform = .identity
            imageView.frame = imageViewFrame
        } else {
            to.view.alpha = 0
            to.view.frame = transitionContext.finalFrame(for: to)
            transitionContext.containerView.addSubview(to.view)
            
            from.view.frame = transitionContext.finalFrame(for: from)
            transitionContext.containerView.addSubview(from.view)
            
            let imageViewFrame = imageView.frame
            imageView.transform = .identity
            imageView.frame = transitionContext.containerView.convert(imageViewFrame, from: imageView.superview)
            transitionContext.containerView.addSubview(imageView)
            
            if usingContextualAnimation {
                guard let referenceView = self.transitionInfo.endingView else {
                    assertionFailure("No. ಠ_ಠ")
                    return
                }
                
                referenceView.alpha = 0
            }
        }
        
        let scaleAnimations = { [weak self] () in
            guard let uSelf = self else {
                return
            }
            
            if usingContextualAnimation {
                guard let referenceView = uSelf.transitionInfo.endingView else {
                    assertionFailure("No. ಠ_ಠ")
                    return
                }
                imageView.frame = transitionContext.containerView.convert(referenceView.frame, from: referenceView.superview)
            } else {
                if uSelf.directionalDismissalPercent > 0 {
                    imageView.frame.origin.y = transitionContext.containerView.frame.origin.y + transitionContext.containerView.frame.size.height
                } else {
                    imageView.frame.origin.y = -imageView.frame.size.height
                }
            }
        }
        
        let scaleCompletion = { [weak self] (_ finished: Bool) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.transitionController(uSelf, didFinishAnimatingWith: imageView, transitionControllerMode: .dismissing)
            
            if usingContextualAnimation {
                guard let referenceView = uSelf.transitionInfo.endingView else {
                    assertionFailure("No. ಠ_ಠ")
                    return
                }
                
                imageView.frame = transitionContext.containerView.convert(referenceView.frame, from: referenceView.superview)
                
                if let imageView = imageView as? FLAnimatedImageView, let referenceView = referenceView as? FLAnimatedImageView {
                    referenceView.ax_syncFrames(with: imageView)
                }
                
                referenceView.alpha = 1
            }
            
            imageView.removeFromSuperview()
            
            if continuingFromInteraction {
                transitionContext.finishInteractiveTransition()
            }
            
            transitionContext.completeTransition(true)
        }
        
        let fadeAnimations = { () in
            to.view.alpha = 1
            from.view.alpha = 0
        }
        
        transitionContext.containerView.layoutIfNeeded()

        var scaleAnimationOptions: UIViewAnimationOptions
        var scaleInitialSpringVelocity: CGFloat
        
        if usingContextualAnimation {
            scaleAnimationOptions = [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent]
            scaleInitialSpringVelocity = 0
        } else {
            var finalImageViewOriginY: CGFloat
            if self.directionalDismissalPercent > 0 {
                finalImageViewOriginY = transitionContext.containerView.frame.origin.y + transitionContext.containerView.frame.size.height
            } else {
                finalImageViewOriginY = -imageView.frame.size.height
            }
            
            scaleAnimationOptions = [.curveLinear, .beginFromCurrentState, .allowAnimatedContent]
            scaleInitialSpringVelocity = abs(self.dismissalVelocityY / (finalImageViewOriginY - imageView.frame.origin.y))
        }

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: scaleInitialSpringVelocity,
                       options: scaleAnimationOptions,
                       animations: scaleAnimations,
                       completion: scaleCompletion)
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: fadeAnimations)
        
        if usingContextualAnimation {
            guard let referenceView = self.transitionInfo.endingView else {
                assertionFailure("No. ಠ_ಠ")
                return
            }
            
            UIView.animateCornerRadii(withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
                                      to: referenceView.layer.cornerRadius,
                                      views: [imageView])
        }
    }
    
    fileprivate func cancelTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) as? PhotosViewController,
            let imageView = from.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        let overlayView = from.overlayView
        
        let animations = { [weak self] () in
            guard let uSelf = self else {
                return
            }
            
            imageView.frame.origin.y = uSelf.imageViewInitialOriginY
            overlayView.navigationBar.frame.origin.y = uSelf.navigationBarInitialOriginY
            overlayView.navigationBarUnderlay.frame.origin.y = uSelf.navigationBarUnderlayInitialOriginY
            (overlayView.captionView as? UIView)?.frame.origin.y = uSelf.captionViewInitialOriginY
            
            to.view.alpha = 0
        }
        
        let completion = { [weak self] (_ finished: Bool) in
            guard let uSelf = self else {
                return
            }

            let usingContextualAnimation = uSelf.canPerformContextualAnimation(using: uSelf.transitionInfo.endingView, in: transitionContext.containerView)
            if usingContextualAnimation {
                guard let referenceView = uSelf.transitionInfo.endingView else {
                    assertionFailure("No. ಠ_ಠ")
                    return
                }
                
                referenceView.alpha = 1
            }
            
            to.view.alpha = 1
            from.view.alpha = 1
            
            imageView.frame = transitionContext.containerView.convert(imageView.frame, to: uSelf.imageViewOriginalSuperview)
            uSelf.imageViewOriginalSuperview?.addSubview(imageView)
            overlayView.frame = transitionContext.containerView.convert(overlayView.frame, to: uSelf.overlayViewOriginalSuperview)
            uSelf.overlayViewOriginalSuperview?.addSubview(overlayView)
            
            if transitionContext.isInteractive {
                transitionContext.cancelInteractiveTransition()
            }
            
            transitionContext.completeTransition(false)
            uSelf.dismissalTransitionContext = nil
        }
        
        UIView.animate(withDuration: (1 - Double(self.dismissalPercent)) * self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
                       animations: animations,
                       completion: completion)
    }
    
    // MARK: - UIViewControllerInteractiveTransitioning
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.dismissalTransitionContext = transitionContext
        
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) as? PhotosViewController,
            let imageView = from.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        to.view.alpha = 0
        to.view.frame = transitionContext.finalFrame(for: to)
        transitionContext.containerView.addSubview(to.view)
        
        from.view.frame = transitionContext.finalFrame(for: from)
        transitionContext.containerView.addSubview(from.view)
        
        self.imageView = imageView
        self.imageViewOriginalFrame = imageView.frame
        self.imageViewOriginalSuperview = imageView.superview
        imageView.frame = transitionContext.containerView.convert(imageView.frame, from: imageView.superview)
        transitionContext.containerView.addSubview(imageView)
        self.imageViewInitialOriginY = imageView.frame.origin.y
        
        let overlayView = from.overlayView
        self.overlayView = overlayView
        self.overlayViewOriginalFrame = overlayView.frame
        self.overlayViewOriginalSuperview = overlayView.superview
        overlayView.frame = transitionContext.containerView.convert(overlayView.frame, from: overlayView.superview)
        transitionContext.containerView.addSubview(overlayView)
        
        self.navigationBarInitialOriginY = overlayView.navigationBar.frame.origin.y
        self.navigationBarUnderlayInitialOriginY = overlayView.navigationBarUnderlay.frame.origin.y
        self.captionViewInitialOriginY = (overlayView.captionView as? UIView)?.frame.origin.y ?? 0
        
        from.view.alpha = 0
        
        let usingContextualAnimation = self.canPerformContextualAnimation(using: self.transitionInfo.endingView, in: transitionContext.containerView)
        if usingContextualAnimation {
            guard let referenceView = self.transitionInfo.endingView else {
                assertionFailure("No. ಠ_ಠ")
                return
            }
            
            referenceView.alpha = 0
        }

    }
    
    // MARK: - Interaction handling
    fileprivate func attach(to photosViewController: PhotosViewController) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        panGestureRecognizer.delegate = self
        photosViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc fileprivate func panAction(_ sender: UIPanGestureRecognizer) {
        self.dismissalVelocityY = sender.velocity(in: sender.view).y
        let translation = sender.translation(in: sender.view?.superview)
        
        switch sender.state {
        case .began:
            self.photosViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        case .changed:
            guard let transitionContext = self.dismissalTransitionContext, let to = transitionContext.viewController(forKey: .to) else {
                return
            }
            
            let height = UIScreen.main.bounds.size.height
            self.directionalDismissalPercent = translation.y > 0 ? min(1, translation.y / height) : max(-1, translation.y / height)
            self.dismissalPercent = min(1, abs(translation.y / height))
            self.completeInteractiveDismissal = (self.dismissalPercent >= DismissalPercentThreshold)

            // this feels right-ish
            let dismissalRatio = (1.5 * self.dismissalPercent / DismissalPercentThreshold)
            
            guard let navigationBar = self.overlayView?.navigationBar, 
                let navigationBarUnderlay = self.overlayView?.navigationBarUnderlay,
                let captionView = self.overlayView?.captionView as? UIView else {
                assertionFailure("No. ಠ_ಠ")
                return
            }
            
            let navigationBarOriginY = max(self.navigationBarInitialOriginY - navigationBarUnderlay.frame.size.height,
                                           self.navigationBarInitialOriginY - (navigationBarUnderlay.frame.size.height * dismissalRatio))
            let navigationBarUnderlayOriginY = max(self.navigationBarUnderlayInitialOriginY - navigationBarUnderlay.frame.size.height,
                                                   self.navigationBarUnderlayInitialOriginY - (navigationBarUnderlay.frame.size.height * dismissalRatio))
            let captionViewOriginY = min(self.captionViewInitialOriginY + captionView.frame.size.height, 
                                         self.captionViewInitialOriginY + (captionView.frame.size.height * dismissalRatio))
            let imageViewOriginY = self.imageViewInitialOriginY + translation.y
            
            UIView.performWithoutAnimation { [weak self] in
                navigationBar.frame.origin.y = navigationBarOriginY
                navigationBarUnderlay.frame.origin.y = navigationBarUnderlayOriginY
                captionView.frame.origin.y = captionViewOriginY
                self?.imageView?.frame.origin.y = imageViewOriginY
            }
            
            to.view.alpha = 1 * min(1, dismissalRatio)
            
        case .ended:
            fallthrough
        case .cancelled:
            guard let transitionContext = self.dismissalTransitionContext else {
                return
            }
            
            if self.completeInteractiveDismissal {
                self.animateTransition(using: transitionContext)
            } else {
                self.cancelTransition(using: transitionContext)
            }
        default:
            break
        }
    }
    
    // MARK: - Helpers
    fileprivate func canPerformContextualAnimation(using referenceView: UIView?, in view: UIView) -> Bool {
        guard let referenceView = referenceView, referenceView.superview != nil else {
            return false
        }
        
        return view.frame.intersects(view.convert(referenceView.frame, from: referenceView.superview))
    }
    
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGestureRecognizer.velocity(in: gestureRecognizer.view)
            return abs(velocity.y) > abs(velocity.x)
        }
        
        return true
    }
    
}

@objc(AXPhotosViewControllerTransitionControllerDelegate) protocol PhotosViewControllerTransitionControllerDelegate {
    
    @objc(transitionController:didFinishAnimatingWithView:animatorMode:)
    func transitionController(_ transitionController: PhotosViewControllerTransitionController,
                              didFinishAnimatingWith view: UIImageView,
                              transitionControllerMode: PhotosViewControllerTransitionControllerMode)
    
}
