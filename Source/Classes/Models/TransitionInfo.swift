//
//  TransitionInfo.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/1/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc(AXTransitionInfo) open class TransitionInfo: NSObject {
    
    /// The view the the transition controller should use for contextual animation during the presentation.
    /// If the reference view that is provided is not currently visible, contextual animation will not occur.
    @objc fileprivate(set) weak var startingView: UIImageView?
    
    /// The view the the transition controller should use for contextual animation during the dismissal.
    /// If the reference view that is provided is not currently visible, contextual animation will not occur.
    @objc fileprivate(set) weak var endingView: UIImageView?
    
    /// The duration of the transition.
    @objc public var duration: TimeInterval = 0.3
    
    /// This value determines whether or not the user can dismiss the `PhotosViewController` by panning vertically.
    @objc fileprivate(set) var interactiveDismissalEnabled: Bool = true
    
    var resolveEndingViewClosure: ((_ photo: PhotoProtocol, _ index: Int) -> Void)?
    
    @objc public init(interactiveDismissalEnabled: Bool, startingView: UIImageView?, endingView: ((_ photo: PhotoProtocol, _ index: Int) -> UIImageView?)?) {
        super.init()
        self.interactiveDismissalEnabled = interactiveDismissalEnabled
        
        if let startingView = startingView {
            guard startingView.bounds != .zero else {
                assertionFailure("'startingView' has invalid geometry: \(startingView)")
                return
            }

            self.startingView = startingView
        }
        
        if let endingView = endingView {
            self.resolveEndingViewClosure = { [weak self] (photo, index) in
                guard let uSelf = self else {
                    return
                }
                
                if let endingView = endingView(photo, index) {
                    guard endingView.bounds != .zero else {
                        uSelf.endingView = nil
                        assertionFailure("'endingView' has invalid geometry: \(endingView)")
                        return
                    }
                    
                    uSelf.endingView = endingView
                } else {
                    uSelf.endingView = nil
                }
            }
        }
    }
    
    @objc public convenience override init() {
        self.init(interactiveDismissalEnabled: true, startingView: nil, endingView: nil)
    }

    @objc public convenience init(startingView: UIImageView?, endingView: ((_ photo: PhotoProtocol, _ index: Int) -> UIImageView?)?) {
        self.init(interactiveDismissalEnabled: true, startingView: startingView, endingView: endingView)
    }
    
}
