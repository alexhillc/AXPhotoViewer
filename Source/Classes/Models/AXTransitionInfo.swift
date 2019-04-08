//
//  AXTransitionInfo.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/1/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc open class AXTransitionInfo: NSObject {
    
    #if os(iOS)
    /// This value determines whether or not the user can dismiss the `PhotosViewController` by panning vertically.
    @objc fileprivate(set) var interactiveDismissalEnabled: Bool = true
    #endif
    
    /// The view the the transition controller should use for contextual animation during the presentation.
    /// If the reference view that is provided is not currently visible, contextual animation will not occur.
    @objc fileprivate(set) weak var startingView: UIImageView?
    
    /// The view the the transition controller should use for contextual animation during the dismissal.
    /// If the reference view that is provided is not currently visible, contextual animation will not occur.
    @objc fileprivate(set) weak var endingView: UIImageView?
    
    /// Internal closure to be called upon dismissal. This will resolve the `endingView` variable.
    var resolveEndingViewClosure: ((_ photo: AXPhotoProtocol, _ index: Int) -> Void)?
    
    /// The damping ratio for the presentation animation as it approaches its quiescent state.
    /// To smoothly decelerate the animation without oscillation, use a value of 1. Employ a damping ratio closer to zero to increase oscillation.
    /// Defaults to 1.
    @objc public var presentationSpringDampingRatio: CGFloat = 1
    
    /// The damping ratio for the dismissal animation as it approaches its quiescent state.
    /// To smoothly decelerate the animation without oscillation, use a value of 1. Employ a damping ratio closer to zero to increase oscillation.
    /// Defaults to 1.
    @objc public var dismissalSpringDampingRatio: CGFloat = 1
    
    /// The fading backdrop that is displayed while the photo viewer is presenting/dismissing.
    /// This closure will be called during presentation and dismissal. Defaults to a black backdrop view.
    @objc public var fadingBackdropView: () -> UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }
    
    /// The duration of the transition.
    @objc public var duration: TimeInterval = 0.3
    
    #if os(iOS)
    @objc public init(interactiveDismissalEnabled: Bool, startingView: UIImageView?, endingView: ((_ photo: AXPhotoProtocol, _ index: Int) -> UIImageView?)?) {
        super.init()
        self.commonInit(interactiveDismissalEnabled: interactiveDismissalEnabled, startingView: startingView, endingView: endingView)
    }
    
    @objc public convenience init(startingView: UIImageView?, endingView: ((_ photo: AXPhotoProtocol, _ index: Int) -> UIImageView?)?) {
        self.init(interactiveDismissalEnabled: true, startingView: startingView, endingView: endingView)
    }
    
    @objc public convenience override init() {
        self.init(interactiveDismissalEnabled: true, startingView: nil, endingView: nil)
    }
    #else
    @objc public init(startingView: UIImageView?, endingView: ((_ photo: AXPhotoProtocol, _ index: Int) -> UIImageView?)?) {
        super.init()
        self.commonInit(interactiveDismissalEnabled: false, startingView: startingView, endingView: endingView)
    }
    
    @objc public convenience override init() {
        self.init(startingView: nil, endingView: nil)
    }
    #endif
    
    fileprivate func commonInit(interactiveDismissalEnabled: Bool, startingView: UIImageView?, endingView: ((_ photo: AXPhotoProtocol, _ index: Int) -> UIImageView?)?) {
        
        #if os(iOS)
        self.interactiveDismissalEnabled = interactiveDismissalEnabled
        #endif
        
        if let startingView = startingView {
            guard startingView.bounds != .zero else {
                assertionFailure("'startingView' has invalid geometry: \(startingView)")
                return
            }

            self.startingView = startingView
        }
        
        if let endingView = endingView {
            self.resolveEndingViewClosure = { [weak self] (photo, index) in
                guard let `self` = self else { return }
                
                if let endingView = endingView(photo, index) {
                    guard endingView.bounds != .zero else {
                        self.endingView = nil
                        assertionFailure("'endingView' has invalid geometry: \(endingView)")
                        return
                    }
                    
                    self.endingView = endingView
                } else {
                    self.endingView = nil
                }
            }
        }
    }
    
}
