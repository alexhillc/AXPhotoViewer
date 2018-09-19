//
//  AXPhotosDismissalAnimator.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/5/18.
//

import UIKit

#if os(iOS)
import FLAnimatedImage
#elseif os(tvOS)
import FLAnimatedImage_tvOS
#endif

class AXPhotosDismissalAnimator: AXPhotosTransitionAnimator, UIViewControllerInteractiveTransitioning {
    
    #if os(iOS)
    /// The distance threshold at which the interactive controller will dismiss upon end touches.
    fileprivate let dismissalPercentThreshold: CGFloat = 0.14
    
    /// The velocity threshold at which the interactive controller will dismiss upon end touches.
    fileprivate let dismissalVelocityYThreshold: CGFloat = 400
    
    /// The velocity threshold at which the interactive controller will dismiss in any direction the user is swiping.
    fileprivate let dismissalVelocityAnyDirectionThreshold: CGFloat = 1000
    
    // Interactive dismissal transition tracking
    fileprivate var dismissalPercent: CGFloat = 0
    fileprivate var directionalDismissalPercent: CGFloat = 0
    fileprivate var dismissalVelocityY: CGFloat = 1
    fileprivate var forceImmediateInteractiveDismissal = false
    fileprivate var completeInteractiveDismissal = false
    weak fileprivate var dismissalTransitionContext: UIViewControllerContextTransitioning?
    
    fileprivate var imageViewInitialCenter: CGPoint = .zero
    fileprivate var imageViewOriginalSuperview: UIView?
    weak fileprivate var imageView: UIImageView?
    
    weak fileprivate var overlayView: AXOverlayView?
    fileprivate var topStackContainerInitialOriginY: CGFloat = .greatestFiniteMagnitude
    fileprivate var bottomStackContainerInitialOriginY: CGFloat = .greatestFiniteMagnitude
    fileprivate var overlayViewOriginalSuperview: UIView?
    #endif
    
    /// Pending animations that can occur when interactive dismissal has not been triggered by the system,
    /// but our pan gesture recognizer is receiving touch events. Processed as soon as the interactive dismissal has been set up.
    fileprivate var pendingChanges = [() -> Void]()
    
    // MARK: - UIViewControllerAnimatedTransitioning    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) else {
                assertionFailure(
                    """
                    Unable to resolve some necessary properties in order to transition. \
                    This should never happen. If this does happen, the animator will complete \
                    the \"transition\" and return immediately.
                    """
                )
                
                if transitionContext.isInteractive {
                    transitionContext.finishInteractiveTransition()
                }
                
                transitionContext.completeTransition(true)
                return
        }
        
        var photosViewController: AXPhotosViewController
        if let from = from as? AXPhotosViewController {
            photosViewController = from
        } else {
            guard let childViewController = from.children.filter({ $0 is AXPhotosViewController }).first as? AXPhotosViewController else {
                assertionFailure(
                    """
                    Could not find AXPhotosViewController in container's children. \
                    This should never happen. If this does happen, the animator will complete \
                    the \"transition\" and return immediately.
                    """
                )
                
                if transitionContext.isInteractive {
                    transitionContext.finishInteractiveTransition()
                }
                
                transitionContext.completeTransition(true)
                return
            }
            
            photosViewController = childViewController
        }
        
        guard let imageView = photosViewController.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
            assertionFailure(
                """
                    Unable to resolve some necessary properties in order to transition. \
                    This should never happen. If this does happen, the animator will complete \
                    the \"transition\" and return immediately.
                    """
            )
            
            if transitionContext.isInteractive {
                transitionContext.finishInteractiveTransition()
            }
            
            transitionContext.completeTransition(true)
            return
        }
        
        let presentersViewRemoved = from.presentationController?.shouldRemovePresentersView ?? false
        if to.view.superview != transitionContext.containerView && presentersViewRemoved {
            to.view.frame = transitionContext.finalFrame(for: to)
            transitionContext.containerView.addSubview(to.view)
        }
        
        if self.fadeView == nil {
            let fadeView = self.transitionInfo.fadingBackdropView()
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
        
        let imageViewCenter = transitionContext.containerView.convert(
            imageView.center,
            from: imageView.superview
        )
        
        let imageViewContainer = AXImageViewTransitionContainer(imageView: imageView)
        imageViewContainer.transform = from.view.transform
        imageViewContainer.center = imageViewCenter
        transitionContext.containerView.addSubview(imageViewContainer)
        imageViewContainer.layoutIfNeeded()
        
        if self.canPerformContextualDismissal() {
            let endingView = self.transitionInfo.endingView!
            endingView.alpha = 0
        }
        
        photosViewController.overlayView.isHidden = true
        
        var offscreenImageViewCenter: CGPoint?
        let scaleAnimations = { [weak self] () in
            guard let `self` = self else {
                return
            }
            
            if self.canPerformContextualDismissal() {
                let endingView = self.transitionInfo.endingView!
                imageViewContainer.contentMode = endingView.contentMode
                imageViewContainer.transform = .identity
                imageViewContainer.frame = transitionContext.containerView.convert(
                    endingView.frame,
                    from: endingView.superview
                )
                imageViewContainer.layoutIfNeeded()
            } else {
                if let offscreenImageViewCenter = offscreenImageViewCenter {
                    imageViewContainer.center = offscreenImageViewCenter
                }
            }
        }
        
        let scaleCompletion = { [weak self] (_ finished: Bool) in
            guard let `self` = self else {
                return
            }
            
            self.delegate?.transitionAnimator(self, didCompleteDismissalWith: imageViewContainer.imageView)
            
            if self.canPerformContextualDismissal() {
                let endingView = self.transitionInfo.endingView!
                if let imageView = imageViewContainer.imageView as? FLAnimatedImageView,
                    let endingView = endingView as? FLAnimatedImageView {
                    endingView.ax_syncFrames(with: imageView)
                }
                
                endingView.alpha = 1
            }
            
            imageViewContainer.removeFromSuperview()
            
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
        
        var scaleAnimationOptions: UIView.AnimationOptions
        var scaleInitialSpringVelocity: CGFloat
        
        if self.canPerformContextualDismissal() {
            scaleAnimationOptions = [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent]
            scaleInitialSpringVelocity = 0
        } else {
            #if os(iOS)
            let extrapolated = self.extrapolateFinalCenter(for: imageViewContainer, in: transitionContext.containerView)
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
            usingSpringWithDamping: self.transitionInfo.dismissalSpringDampingRatio,
            initialSpringVelocity: scaleInitialSpringVelocity,
            options: scaleAnimationOptions,
            animations: scaleAnimations,
            completion: scaleCompletion
        )
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext) * self.fadeInOutTransitionRatio,
            delay: 0,
            options: [.curveEaseInOut],
            animations: fadeAnimations,
            completion: fadeCompletion
        )
        
        if self.canPerformContextualDismissal() {
            let endingView = self.transitionInfo.endingView!
            UIView.animateCornerRadii(
                withDuration: self.transitionDuration(using: transitionContext) * self.fadeInOutTransitionRatio,
                to: endingView.layer.cornerRadius,
                views: [imageViewContainer]
            )
        }
    }
    
    // MARK: - UIViewControllerInteractiveTransitioning
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        #if os(iOS)
        self.dismissalTransitionContext = transitionContext
        
        guard let to = transitionContext.viewController(forKey: .to),
            let from = transitionContext.viewController(forKey: .from) else {
                assertionFailure(
                    """
                    Unable to resolve some necessary properties in order to transition. \
                    This should never happen. If this does happen, the animator will complete \
                    the \"transition\" and return immediately.
                    """
                )
                
                if transitionContext.isInteractive {
                    transitionContext.finishInteractiveTransition()
                }
                
                transitionContext.completeTransition(true)
                return
        }
        
        var photosViewController: AXPhotosViewController
        if let from = from as? AXPhotosViewController {
            photosViewController = from
        } else {
            guard let childViewController = from.children.filter({ $0 is AXPhotosViewController }).first as? AXPhotosViewController else {
                assertionFailure(
                    """
                    Could not find AXPhotosViewController in container's children. \
                    This should never happen. If this does happen, the animator will complete \
                    the \"transition\" and return immediately.
                    """
                )
                
                if transitionContext.isInteractive {
                    transitionContext.finishInteractiveTransition()
                }
                
                transitionContext.completeTransition(true)
                return
            }
            
            photosViewController = childViewController
        }
        
        guard let imageView = photosViewController.currentPhotoViewController?.zoomingImageView.imageView as UIImageView? else {
            assertionFailure(
                """
                    Unable to resolve some necessary properties in order to transition. \
                    This should never happen. If this does happen, the animator will complete \
                    the \"transition\" and return immediately.
                    """
            )
            
            if transitionContext.isInteractive {
                transitionContext.finishInteractiveTransition()
            }
            
            transitionContext.completeTransition(true)
            return
        }
        
        self.imageView = imageView
        self.overlayView = photosViewController.overlayView
        
        // if we're going to force an immediate dismissal, we can just return here
        // this setup will be done in `animateDismissal(_:)`
        if self.forceImmediateInteractiveDismissal {
            self.processPendingChanges()
            return
        }
        
        let presentersViewRemoved = from.presentationController?.shouldRemovePresentersView ?? false
        if presentersViewRemoved {
            to.view.frame = transitionContext.finalFrame(for: to)
            transitionContext.containerView.addSubview(to.view)
        }
        
        let fadeView = self.transitionInfo.fadingBackdropView()
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
        
        self.processPendingChanges()
        #else
        fatalError("Interactive animations are not supported on tvOS.")
        #endif
    }
    
    #if os(iOS)
    // MARK: - Cancel interactive transition
    fileprivate func cancelTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let from = transitionContext.viewController(forKey: .from) else {
            assertionFailure("No. ಠ_ಠ")
            return
        }
        
        var photosViewController: AXPhotosViewController
        if let from = from as? AXPhotosViewController {
            photosViewController = from
        } else {
            guard let childViewController = from.children.filter({ $0 is AXPhotosViewController }).first as? AXPhotosViewController else {
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
            
            self.delegate?.transitionAnimatorDidCancelDismissal(self)
            
            if transitionContext.isInteractive {
                transitionContext.cancelInteractiveTransition()
            }
            
            transitionContext.completeTransition(false)
            self.dismissalTransitionContext = nil
        }
        
        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: self.transitionInfo.dismissalSpringDampingRatio,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowAnimatedContent],
            animations: animations,
            completion: completion
        )
    }
    
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
                self.directionalDismissalPercent = (translation.y > 0)
                    ? min(1, translation.y / height)
                    : max(-1, translation.y / height)
                self.dismissalPercent = min(1, abs(translation.y / height))
                self.completeInteractiveDismissal = (self.dismissalPercent >= self.dismissalPercentThreshold)
                    || (abs(self.dismissalVelocityY) >= self.dismissalVelocityYThreshold)
                
                // this feels right-ish
                let dismissalRatio = (1.2 * self.dismissalPercent / self.dismissalPercentThreshold)
                
                let topStackContainerOriginY = max(
                    self.topStackContainerInitialOriginY - topStackContainer.frame.size.height,
                    self.topStackContainerInitialOriginY - (topStackContainer.frame.size.height * dismissalRatio)
                )
                let bottomStackContainerOriginY = min(
                    self.bottomStackContainerInitialOriginY + bottomStackContainer.frame.size.height,
                    self.bottomStackContainerInitialOriginY + (bottomStackContainer.frame.size.height * dismissalRatio)
                )
                let imageViewCenterY = self.imageViewInitialCenter.y + translation.y
                
                UIView.performWithoutAnimation {
                    topStackContainer.frame.origin.y = topStackContainerOriginY
                    bottomStackContainer.frame.origin.y = bottomStackContainerOriginY
                    self.imageView?.center.y = imageViewCenterY
                }
                
                self.fadeView?.alpha = 1 - (1 * min(1, dismissalRatio))
            }
            
            if self.imageView == nil || self.overlayView == nil {
                self.pendingChanges.append(animation)
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
                    self.animateTransition(using: transitionContext)
                } else {
                    self.cancelTransition(using: transitionContext)
                }
            }
            
            // `imageView`, `overlayView` set in `startInteractiveTransition(_:)`
            if self.imageView == nil || self.overlayView == nil {
                self.pendingChanges.append(animation)
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
    fileprivate func extrapolateFinalCenter(for view: UIView,
                                            in containingView: UIView) -> (center: CGPoint, changed: CGFloat) {
        
        let endingOrientation = UIApplication.shared.statusBarOrientation
        let startingOrientation = endingOrientation.by(transforming: view.transform)
        
        let dismissFromBottom = (abs(self.dismissalVelocityY) > self.dismissalVelocityAnyDirectionThreshold)
            ? self.dismissalVelocityY >= 0
            : self.directionalDismissalPercent >= 0
        let viewRect = view.convert(view.bounds, to: containingView)
        var viewCenter = view.center
        
        switch startingOrientation {
        case .landscapeLeft:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                } else {
                    viewCenter.y = -(viewRect.size.height / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    viewCenter.y = -(viewRect.size.height / 2)
                } else {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    viewCenter.x = -(viewRect.size.width / 2)
                } else {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                }
            default:
                if dismissFromBottom {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                } else {
                    viewCenter.x = -(viewRect.size.width / 2)
                }
            }
        case .landscapeRight:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    viewCenter.y = -(viewRect.size.height / 2)
                } else {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                } else {
                    viewCenter.y = -(viewRect.size.height / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                } else {
                    viewCenter.x = -(viewRect.size.width / 2)
                }
            default:
                if dismissFromBottom {
                    viewCenter.x = -(viewRect.size.width / 2)
                } else {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                }
            }
        case .portraitUpsideDown:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                } else {
                    viewCenter.x = -(viewRect.size.width / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    viewCenter.x = -(viewRect.size.width / 2)
                } else {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                } else {
                    viewCenter.y = -(viewRect.size.height / 2)
                }
            default:
                if dismissFromBottom {
                    viewCenter.y = -(viewRect.size.height / 2)
                } else {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                }
            }
        default:
            switch endingOrientation {
            case .landscapeLeft:
                if dismissFromBottom {
                    viewCenter.x = -(viewRect.size.width / 2)
                } else {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                }
            case .landscapeRight:
                if dismissFromBottom {
                    viewCenter.x = containingView.frame.size.width + (viewRect.size.width / 2)
                } else {
                    viewCenter.x = -(viewRect.size.width / 2)
                }
            case .portraitUpsideDown:
                if dismissFromBottom {
                    viewCenter.y = -(viewRect.size.height / 2)
                } else {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                }
            default:
                if dismissFromBottom {
                    viewCenter.y = containingView.frame.size.height + (viewRect.size.height / 2)
                } else {
                    viewCenter.y = -(viewRect.size.height / 2)
                }
            }
        }
        
        if abs(view.center.x - viewCenter.x) >= .ulpOfOne {
            return (viewCenter, viewCenter.x)
        } else {
            return (viewCenter, viewCenter.y)
        }
    }
    #endif
    
    // MARK: - Helpers
    fileprivate func canPerformContextualDismissal() -> Bool {
        guard let endingView = self.transitionInfo.endingView, let endingViewSuperview = endingView.superview else {
            return false
        }
        
        return UIScreen.main.bounds.intersects(endingViewSuperview.convert(endingView.frame, to: nil))
    }
    
    fileprivate func processPendingChanges() {
        for animation in self.pendingChanges {
            animation()
        }
        
        self.pendingChanges.removeAll()
    }

}
