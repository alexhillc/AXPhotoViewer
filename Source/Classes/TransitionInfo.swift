//
//  TransitionInfo.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

@objc(AXTransitionInfo) open class TransitionInfo: NSObject {
    
    /// The view the the transition controller should use for contextual animation during the presentation.
    /// If the reference view that is provided is not currently visible, contextual animation will not occur.
    fileprivate(set) weak var startingView: UIImageView?
    
    /// The view the the transition controller should use for contextual animation during the dismissal.
    /// If the reference view that is provided is not currently visible, contextual animation will not occur.
    fileprivate(set) weak var endingView: UIImageView?
    
    /// The duration of the transition.
    public var duration: TimeInterval = 0.35
    
    /// This value determines whether or not the user can dismiss the `PhotosViewController` by panning vertically.
    fileprivate(set) var interactiveDismissalEnabled: Bool = true
    
    var resolveEndingViewClosure: ((_ photo: PhotoProtocol, _ index: Int) -> Void)?
    
    public init(interactiveDismissalEnabled: Bool, startingView: UIImageView?, endingView: ((_ photo: PhotoProtocol, _ index: Int) -> UIImageView?)?) {
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
                        assertionFailure("'endingView' has invalid geometry: \(endingView)")
                        return
                    }
                    
                    uSelf.endingView = endingView
                }
            }
        }
    }
    
    public convenience override init() {
        self.init(interactiveDismissalEnabled: true, startingView: nil, endingView: nil)
    }

}
