//
//  AXPhotosTransitionController.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/4/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit

#if os(iOS)
import FLAnimatedImage
#elseif os(tvOS)
import FLAnimatedImage_tvOS
#endif

@objc enum AXPhotosTransitionControllerMode: Int {
    case presenting, dismissing
}

@objc class AXPhotosTransitionController: NSObject, UIViewControllerAnimatedTransitioning,
                                                    UIViewControllerInteractiveTransitioning {
    
    #if os(iOS)
    /// The distance threshold at which the interactive controller will dismiss upon end touches.
    fileprivate let DismissalPercentThreshold: CGFloat = 0.14
    
    /// The velocity threshold at which the interactive controller will dismiss upon end touches.
    fileprivate let DismissalVelocityYThreshold: CGFloat = 400
    
    /// The velocity threshold at which the interactive controller will dismiss in any direction the user is swiping.
    fileprivate let DismissalVelocityAnyDirectionThreshold: CGFloat = 1000
    
    // Interactive dismissal transition tracking
    fileprivate var dismissalPercent: CGFloat = 0
    fileprivate var directionalDismissalPercent: CGFloat = 0
    fileprivate var dismissalVelocityY: CGFloat = 1
    fileprivate var forceImmediateInteractiveDismissal = false
    fileprivate var completeInteractiveDismissal = false
    
    fileprivate var imageViewInitialCenter: CGPoint = .zero
    fileprivate var imageViewOriginalSuperview: UIView?
    
    weak fileprivate var overlayView: AXOverlayView?
    fileprivate var topStackContainerInitialOriginY: CGFloat = .greatestFiniteMagnitude
    fileprivate var bottomStackContainerInitialOriginY: CGFloat = .greatestFiniteMagnitude
    fileprivate var overlayViewOriginalSuperview: UIView?
    #endif
    
    fileprivate let FadeInOutTransitionRatio: Double = 1/3
    fileprivate let TransitionAnimSpringDampening: CGFloat = 1
    fileprivate var fadeView: UIView?
    
    fileprivate static let supportedModalPresentationStyles: [UIModalPresentationStyle] =  [.fullScreen,
                                                                                            .currentContext,
                                                                                            .custom,
                                                                                            .overFullScreen,
                                                                                            .overCurrentContext]
    
    weak var delegate: AXPhotosTransitionControllerDelegate?
    var mode: AXPhotosTransitionControllerMode = .presenting
    var transitionInfo: AXTransitionInfo
    
    /// Pending animations that can occur when interactive dismissal has not been triggered by the system, 
    /// but our pan gesture recognizer is receiving touch events. Processed as soon as the interactive dismissal has been set up.
    fileprivate var pendingAnimations = [() -> Void]()
    
    weak fileprivate var dismissalTransitionContext: UIViewControllerContextTransitioning?
    
    weak fileprivate var imageView: UIImageView?
    
    var supportsContextualPresentation: Bool {
        get {
            return (self.transitionInfo.startingView != nil)
        }
    }
    
    var supportsContextualDismissal: Bool {
        get {
            return (self.transitionInfo.endingView != nil)
        }
    }
    
    var supportsInteractiveDismissal: Bool {
        get {
            #if os(iOS)
            return self.transitionInfo.interactiveDismissalEnabled
            #else
            return false
            #endif
        }
    }
    
    func supportsModalPresentationStyle(_ modalPresentationStyle: UIModalPresentationStyle) -> Bool {
        return type(of: self).supportedModalPresentationStyles.contains(modalPresentationStyle)
    }
    
    init(transitionInfo: AXTransitionInfo) {
        self.transitionInfo = transitionInfo
        super.init()
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transitionInfo.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.mode == .presenting {
            self.animatePresentation(using: transitionContext)
        } else if self.mode == .dismissing {
            self.animateDismissal(using: transitionContext)
        }
    }
    
    fileprivate func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from),
            let referenceView = self.transitionInfo.startingView,
            let referenceViewCopy = self.transitionInfo.startingView?.ax_copy() else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        let fadeView = UIView()
        fadeView.backgroundColor = .black
        fadeView.alpha = 0
        fadeView.frame = transitionContext.finalFrame(for: to)
        transitionContext.containerView.addSubview(fadeView)
        self.fadeView = fadeView
        
        to.view.alpha = 0
        to.view.frame = transitionContext.finalFrame(for: to)
        transitionContext.containerView.addSubview(to.view)
        
        transitionContext.containerView.layoutIfNeeded()
        
        let referenceViewFrame = referenceView.frame
        referenceView.transform = .identity
        referenceView.frame = referenceViewFrame
        
        let referenceViewCenter = referenceView.center
        referenceViewCopy.transform = from.view.transform
        referenceViewCopy.center = transitionContext.containerView.convert(referenceViewCenter, from: referenceView.superview)
        transitionContext.containerView.addSubview(referenceViewCopy)
        
        referenceView.alpha = 0

        var imageAspectRatio: CGFloat = 1
        if let image = referenceViewCopy.image {
            imageAspectRatio = image.size.width / image.size.height
        }
        
        let referenceViewAspectRatio = referenceViewCopy.bounds.size.width / referenceViewCopy.bounds.size.height
        var aspectRatioAdjustedSize = referenceViewCopy.bounds.size
        if abs(referenceViewAspectRatio - imageAspectRatio) > .ulpOfOne {
            aspectRatioAdjustedSize.width = aspectRatioAdjustedSize.height * imageAspectRatio
        }
        
        let scale = min(to.view.frame.size.width / aspectRatioAdjustedSize.width, to.view.frame.size.height / aspectRatioAdjustedSize.height)
        let scaledSize = CGSize(width: aspectRatioAdjustedSize.width * scale, height: aspectRatioAdjustedSize.height * scale)
        let scaleAnimations = { () in
            referenceViewCopy.transform = .identity
            referenceViewCopy.frame.size = scaledSize
            referenceViewCopy.center = to.view.center
        }
        
        let scaleCompletion = { [weak self] (_ finished: Bool) in
            guard let `self` = self else {
                return
            }
            
            self.delegate?.transitionController(self, didFinishAnimatingWith: referenceViewCopy, transitionControllerMode: .presenting)
            
            to.view.alpha = 1
            referenceView.alpha = 1
            referenceViewCopy.removeFromSuperview()
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
            usingSpringWithDamping: TransitionAnimSpringDampening,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
            animations: scaleAnimations,
            completion: scaleCompletion
        )
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
            delay: 0,
            options: [.curveEaseInOut],
            animations: fadeAnimations
        )
        
        UIView.animateCornerRadii(
            withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
            to: 0,
            views: [referenceViewCopy]
        )
    }
    
    fileprivate func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        var photosViewController: AXPhotosViewController
        if let from = from as? AXPhotosViewController {
            photosViewController = from
        } else {
            guard let childViewController = from.childViewControllers.filter({ $0 is AXPhotosViewController }).first as? AXPhotosViewController else {
                assertionFailure("Could not find AXPhotosViewController in container's children.")
                return
            }
            
            photosViewController = childViewController
        }
        
        guard let imageView = photosViewController.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
            assertionFailure("No. ಠ_ಠ")
            return
        }
        
        let presentersViewRemoved = from.presentationController?.shouldRemovePresentersView ?? false
        if to.view.superview != transitionContext.containerView && presentersViewRemoved {
            to.view.frame = transitionContext.finalFrame(for: to)
            transitionContext.containerView.addSubview(to.view)
        }
        
        if self.fadeView == nil {
            let fadeView = UIView()
            fadeView.backgroundColor = .black
            fadeView.frame = transitionContext.finalFrame(for: from)
            transitionContext.containerView.insertSubview(fadeView, aboveSubview: to.view)
            self.fadeView = fadeView
        }
        
        if from.view.superview != transitionContext.containerView {
            from.view.frame = transitionContext.finalFrame(for: from)
            transitionContext.containerView.addSubview(from.view)
        }
        
        transitionContext.containerView.layoutIfNeeded()
        
        let imageViewFrame = imageView.frame
        imageView.transform = .identity
        imageView.frame = imageViewFrame
        
        if imageView.superview != transitionContext.containerView {
            let imageViewCenter = imageView.center
            imageView.transform = from.view.transform
            imageView.center = transitionContext.containerView.convert(imageViewCenter, from: imageView.superview)
            transitionContext.containerView.addSubview(imageView)
        }
        
        if self.canPerformContextualDismissal() {
            guard let referenceView = self.transitionInfo.endingView else {
                assertionFailure("Expected non-nil endingView!")
                return
            }
            
            imageView.contentMode = referenceView.contentMode
            referenceView.alpha = 0
        }
        
        photosViewController.overlayView.isHidden = true
        
        var offscreenImageViewCenter: CGPoint?
        let scaleAnimations = { [weak self] () in
            guard let `self` = self else {
                return
            }
            
            if self.canPerformContextualDismissal() {
                guard let referenceView = self.transitionInfo.endingView else {
                    assertionFailure("Expected non-nil endingView!")
                    return
                }
                
                imageView.transform = .identity
                imageView.frame = transitionContext.containerView.convert(referenceView.frame, from: referenceView.superview)
            } else {
                if let offscreenImageViewCenter = offscreenImageViewCenter {
                    imageView.center = offscreenImageViewCenter
                }
            }
        }
        
        let scaleCompletion = { [weak self] (_ finished: Bool) in
            guard let `self` = self else {
                return
            }
            
            self.delegate?.transitionController(self, didFinishAnimatingWith: imageView, transitionControllerMode: .dismissing)
            
            if self.canPerformContextualDismissal() {
                guard let referenceView = self.transitionInfo.endingView else {
                    assertionFailure("Expected non-nil endingView!")
                    return
                }
                
                if let imageView = imageView as? FLAnimatedImageView, let referenceView = referenceView as? FLAnimatedImageView {
                    referenceView.ax_syncFrames(with: imageView)
                }
                
                referenceView.alpha = 1
            }
            
            imageView.removeFromSuperview()
            
            if transitionContext.isInteractive {
                transitionContext.finishInteractiveTransition()
            }
            
            transitionContext.completeTransition(true)
        }
        
        let fadeAnimations = { [weak self] in
            self?.fadeView?.alpha = 0
            from.view.alpha = 0
        }
        
        let fadeCompletion = { [weak self] (_ finished: Bool) in
            self?.fadeView?.removeFromSuperview()
            self?.fadeView = nil
        }
        
        var scaleAnimationOptions: UIViewAnimationOptions
        var scaleInitialSpringVelocity: CGFloat
        
        if self.canPerformContextualDismissal() {
            scaleAnimationOptions = [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent]
            scaleInitialSpringVelocity = 0
        } else {
            #if os(iOS)
            let extrapolated = self.extrapolateFinalCenter(for: imageView, in: transitionContext.containerView)
            offscreenImageViewCenter = extrapolated.center
            
            if self.forceImmediateInteractiveDismissal {
                scaleAnimationOptions = [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent]
                scaleInitialSpringVelocity = 0
            } else {
                var divisor: CGFloat = 1
                let changed = extrapolated.changed
                if .ulpOfOne >= abs(changed - extrapolated.center.x) {
                    divisor = abs(changed - imageView.frame.origin.x)
                } else {
                    divisor = abs(changed - imageView.frame.origin.y)
                }
                
                scaleAnimationOptions = [.curveLinear, .beginFromCurrentState, .allowAnimatedContent]
                scaleInitialSpringVelocity = abs(self.dismissalVelocityY / divisor)
            }
            #else
            scaleAnimationOptions = [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent]
            scaleInitialSpringVelocity = 0
            #endif
        }

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: TransitionAnimSpringDampening,
            initialSpringVelocity: scaleInitialSpringVelocity,
            options: scaleAnimationOptions,
            animations: scaleAnimations,
            completion: scaleCompletion
        )
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
            delay: 0,
            options: [.curveEaseInOut],
            animations: fadeAnimations,
            completion: fadeCompletion
        )
        
        if self.canPerformContextualDismissal() {
            guard let referenceView = self.transitionInfo.endingView else {
                assertionFailure("No. ಠ_ಠ")
                return
            }
            
            UIView.animateCornerRadii(
                withDuration: self.transitionDuration(using: transitionContext) * FadeInOutTransitionRatio,
                to: referenceView.layer.cornerRadius,
                views: [imageView]
            )
        }
    }
    
    // MARK: - UIViewControllerInteractiveTransitioning
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        #if os(iOS)
        self.dismissalTransitionContext = transitionContext
        
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        var photosViewController: AXPhotosViewController
        if let from = from as? AXPhotosViewController {
            photosViewController = from
        } else {
            guard let childViewController = from.childViewControllers.filter({ $0 is AXPhotosViewController }).first as? AXPhotosViewController else {
                assertionFailure("Could not find AXPhotosViewController in container's children.")
                return
            }
            
            photosViewController = childViewController
        }
        
        guard let imageView = photosViewController.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
            assertionFailure("No. ಠ_ಠ")
            return
        }
        
        self.imageView = imageView
        self.overlayView = photosViewController.overlayView
        
        // if we're going to force an immediate dismissal, we can just return here
        // this setup will be done in `animateDismissal(_:)`
        if self.forceImmediateInteractiveDismissal {
            self.processPendingAnimations()
            return
        }
        
        let presentersViewRemoved = from.presentationController?.shouldRemovePresentersView ?? false
        if presentersViewRemoved {
            to.view.frame = transitionContext.finalFrame(for: to)
            transitionContext.containerView.addSubview(to.view)
        }
        
        let fadeView = UIView()
        fadeView.backgroundColor = .black
        fadeView.frame = transitionContext.finalFrame(for: from)
        transitionContext.containerView.insertSubview(fadeView, aboveSubview: to.view)
        self.fadeView = fadeView
        
        from.view.frame = transitionContext.finalFrame(for: from)
        transitionContext.containerView.addSubview(from.view)
        
        transitionContext.containerView.layoutIfNeeded()
        
        self.imageViewOriginalSuperview = imageView.superview
        imageView.center = transitionContext.containerView.convert(imageView.center, from: imageView.superview)
        transitionContext.containerView.addSubview(imageView)
        self.imageViewInitialCenter = imageView.center
        
        let overlayView = photosViewController.overlayView
        self.overlayViewOriginalSuperview = overlayView.superview
        overlayView.frame = transitionContext.containerView.convert(overlayView.frame, from: overlayView.superview)
        transitionContext.containerView.addSubview(overlayView)
        
        self.topStackContainerInitialOriginY = overlayView.topStackContainer.frame.origin.y
        self.bottomStackContainerInitialOriginY = overlayView.bottomStackContainer.frame.origin.y
        
        from.view.alpha = 0
        
        if self.canPerformContextualDismissal() {
            guard let referenceView = self.transitionInfo.endingView else {
                assertionFailure("No. ಠ_ಠ")
                return
            }
            
            referenceView.alpha = 0
        }
        
        self.processPendingAnimations()
        #else
        fatalError("Interactive animations are not supported on tvOS.")
        #endif
    }
    
    #if os(iOS)
    fileprivate func cancelTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let from = transitionContext.viewController(forKey: .from) else {
                assertionFailure("No. ಠ_ಠ")
                return
        }
        
        var photosViewController: AXPhotosViewController
        if let from = from as? AXPhotosViewController {
            photosViewController = from
        } else {
            guard let childViewController = from.childViewControllers.filter({ $0 is AXPhotosViewController }).first as? AXPhotosViewController else {
                assertionFailure("Could not find AXPhotosViewController in container's children.")
                return
            }
            
            photosViewController = childViewController
        }
        
        guard let imageView = photosViewController.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
            assertionFailure("No. ಠ_ಠ")
            return
        }
        
        let overlayView = photosViewController.overlayView
        let animations = { [weak self] () in
            guard let `self` = self else {
                return
            }
            
            imageView.center.y = self.imageViewInitialCenter.y
            overlayView.topStackContainer.frame.origin.y = self.topStackContainerInitialOriginY
            overlayView.bottomStackContainer.frame.origin.y = self.bottomStackContainerInitialOriginY
            
            self.fadeView?.alpha = 1
        }
        
        let completion = { [weak self] (_ finished: Bool) in
            guard let `self` = self else {
                return
            }

            if self.canPerformContextualDismissal() {
                guard let referenceView = self.transitionInfo.endingView else {
                    assertionFailure("No. ಠ_ಠ")
                    return
                }
                
                referenceView.alpha = 1
            }
            
            self.fadeView?.removeFromSuperview()
            from.view.alpha = 1
            
            imageView.frame = transitionContext.containerView.convert(imageView.frame, to: self.imageViewOriginalSuperview)
            self.imageViewOriginalSuperview?.addSubview(imageView)
            overlayView.frame = transitionContext.containerView.convert(overlayView.frame, to: self.overlayViewOriginalSuperview)
            self.overlayViewOriginalSuperview?.addSubview(overlayView)
            
            self.imageViewInitialCenter = .zero
            self.imageViewOriginalSuperview = nil
            
            self.topStackContainerInitialOriginY = .greatestFiniteMagnitude
            self.bottomStackContainerInitialOriginY = .greatestFiniteMagnitude
            self.overlayViewOriginalSuperview = nil
            
            self.dismissalPercent = 0
            self.directionalDismissalPercent = 0
            self.dismissalVelocityY = 1
            
            if transitionContext.isInteractive {
                transitionContext.cancelInteractiveTransition()
            }
            
            transitionContext.completeTransition(false)
            self.dismissalTransitionContext = nil
        }
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: TransitionAnimSpringDampening,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
            animations: animations,
            completion: completion
        )
    }
    #endif
    
    // MARK: - Helpers
    fileprivate func processPendingAnimations() {
        for animation in self.pendingAnimations {
            animation()
        }
        
        self.pendingAnimations.removeAll()
    }
    
    fileprivate func canPerformContextualDismissal() -> Bool {
        guard let endingView = self.transitionInfo.endingView, let endingViewSuperview = endingView.superview else {
            return false
        }
        
        return UIScreen.main.bounds.intersects(endingViewSuperview.convert(endingView.frame, to: nil))
    }
    
    #if os(iOS)
    // MARK: - Interaction handling
    public func didPanWithGestureRecognizer(_ sender: UIPanGestureRecognizer, in viewController: UIViewController) {
        
        self.dismissalVelocityY = sender.velocity(in: sender.view).y
        let translation = sender.translation(in: sender.view?.superview)
        
        switch sender.state {
        case .began:
            self.overlayView = nil

            let endingOrientation = UIApplication.shared.statusBarOrientation
            let startingOrientation = endingOrientation.by(transforming: viewController.view.transform)
            
            let shouldForceImmediateInteractiveDismissal = (startingOrientation != endingOrientation)
            if shouldForceImmediateInteractiveDismissal {
                // arbitrary dismissal percentages
                self.directionalDismissalPercent = self.dismissalVelocityY > 0 ? 1 : -1
                self.dismissalPercent = 1
                self.forceImmediateInteractiveDismissal = true
                self.completeInteractiveDismissal = true
                
                // immediately trigger `cancelled` for dismissal
                sender.isEnabled = false
            }
        case .changed:
            let animation = { [weak self] in
                guard let `self` = self,
                    let topStackContainer = self.overlayView?.topStackContainer,
                    let bottomStackContainer = self.overlayView?.bottomStackContainer else {
                        assertionFailure("No. ಠ_ಠ")
                        return
                }
                
                let height = UIScreen.main.bounds.size.height
                self.directionalDismissalPercent = translation.y > 0 ? min(1, translation.y / height) : max(-1, translation.y / height)
                self.dismissalPercent = min(1, abs(translation.y / height))
                self.completeInteractiveDismissal = (self.dismissalPercent >= self.DismissalPercentThreshold) ||
                                                     (abs(self.dismissalVelocityY) >= self.DismissalVelocityYThreshold)
                
                // this feels right-ish
                let dismissalRatio = (1.2 * self.dismissalPercent / self.DismissalPercentThreshold)
                
                let topStackContainerOriginY = max(self.topStackContainerInitialOriginY - topStackContainer.frame.size.height,
                                               self.topStackContainerInitialOriginY - (topStackContainer.frame.size.height * dismissalRatio))
                let bottomStackContainerOriginY = min(self.bottomStackContainerInitialOriginY + bottomStackContainer.frame.size.height,
                                             self.bottomStackContainerInitialOriginY + (bottomStackContainer.frame.size.height * dismissalRatio))
                let imageViewCenterY = self.imageViewInitialCenter.y + translation.y
                
                UIView.performWithoutAnimation {
                    topStackContainer.frame.origin.y = topStackContainerOriginY
                    bottomStackContainer.frame.origin.y = bottomStackContainerOriginY
                    self.imageView?.center.y = imageViewCenterY
                }
                
                self.fadeView?.alpha = 1 - (1 * min(1, dismissalRatio))
            }
            
            if self.imageView == nil || self.overlayView == nil {
                self.pendingAnimations.append(animation)
                return
            }
            
            animation()
            
        case .ended:
            fallthrough
        case .cancelled:
            let animation = { [weak self] in
                guard let `self` = self,
                    let transitionContext = self.dismissalTransitionContext,
                    let _ = self.overlayView?.topStackContainer,
                    let _ = self.overlayView?.bottomStackContainer else {
                        return
                }
                
                if self.completeInteractiveDismissal {
                    self.animateDismissal(using: transitionContext)
                } else {
                    self.cancelTransition(using: transitionContext)
                }
            }
            
            // `imageView`, `overlayView` set in `startInteractiveTransition(_:)`
            if self.imageView == nil || self.overlayView == nil {
                self.pendingAnimations.append(animation)
                return
            }
            
            animation()
            
        default:
            break
        }
    }
        
    /// Extrapolate the "final" offscreen center value for an image view in a view given the starting and ending orientations.
    ///
    /// - Parameters:
    ///   - imageView: The image view to retrieve the final offscreen center value for.
    ///   - view: The view that is containing the imageView. Most likely the superview.
    /// - Returns: A tuple containing the final center of the imageView, as well as the value that was adjusted from the original `center` value.
    fileprivate func extrapolateFinalCenter(for imageView: UIImageView,
                                            in view: UIView) -> (center: CGPoint, changed: CGFloat) {
        
        let endingOrientation = UIApplication.shared.statusBarOrientation
        let startingOrientation = endingOrientation.by(transforming: imageView.transform)
        
        let dismissFromBottom = abs(self.dismissalVelocityY) > self.DismissalVelocityAnyDirectionThreshold ?
            self.dismissalVelocityY >= 0 :
            self.directionalDismissalPercent >= 0
        let imageViewRect = imageView.convert(imageView.bounds, to: view)
        var imageViewCenter = imageView.center
        
        switch startingOrientation {
        case .landscapeLeft:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                }
            default:
                if dismissFromBottom {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                }
            }
        case .landscapeRight:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                }
            default:
                if dismissFromBottom {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                }
            }
        case .portraitUpsideDown:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                }
            default:
                if dismissFromBottom {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                }
            }
        default:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    imageViewCenter.x = view.frame.size.width + (imageViewRect.size.width / 2)
                } else {
                    imageViewCenter.x = -(imageViewRect.size.width / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                }
            default:
                if dismissFromBottom {
                    imageViewCenter.y = view.frame.size.height + (imageViewRect.size.height / 2)
                } else {
                    imageViewCenter.y = -(imageViewRect.size.height / 2)
                }
            }
        }
        
        if abs(imageView.center.x - imageViewCenter.x) >= .ulpOfOne {
            return (imageViewCenter, imageViewCenter.x)
        } else {
            return (imageViewCenter, imageViewCenter.y)
        }
    }
    #endif
    
}

@objc protocol AXPhotosTransitionControllerDelegate {
    
    @objc(transitionController:didFinishAnimatingWithView:animatorMode:)
    func transitionController(_ transitionController: AXPhotosTransitionController,
                              didFinishAnimatingWith view: UIImageView,
                              transitionControllerMode: AXPhotosTransitionControllerMode)
    
}
