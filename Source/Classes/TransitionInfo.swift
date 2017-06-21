//
//  TransitionInfo.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

@objc(AXTransitionInfo) open class TransitionInfo: NSObject {
    
    /// The view the the transition controller should use for contextual animation. 
    /// This value can be changed to accomodate for presentation/dismissal.
    /// If the reference view that is provided is not currently visible, contextual animation will not occur.
    public weak var referenceView: UIImageView?
    
    /// The duration of the transition.
    public var duration: TimeInterval = 0.35
    
    /// This value determines whether or not the user can dismiss the `PhotosViewController` by panning vertically.
    fileprivate(set) var interactiveDismissalEnabled: Bool = true
    
    public init(referenceView: UIImageView? = nil, interactiveDismissalEnabled: Bool? = nil) {
        self.referenceView = referenceView
        if let uInteractiveDismissalEnabled = interactiveDismissalEnabled {
            self.interactiveDismissalEnabled = uInteractiveDismissalEnabled
        }
        super.init()
    }

}
