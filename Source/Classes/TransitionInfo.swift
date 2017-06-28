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
    
    var resolveEndingView: ((_ photo: PhotoProtocol, _ index: Int) -> Void)?
    
    /// The duration of the transition.
    public var duration: TimeInterval = 0.35
    
    /// This value determines whether or not the user can dismiss the `PhotosViewController` by panning vertically.
    fileprivate(set) var interactiveDismissalEnabled: Bool = true
    
    public init(interactiveDismissalEnabled: Bool, startingView: UIImageView?, endingView: ((_ photo: PhotoProtocol, _ index: Int) -> UIImageView?)?) {
        super.init()
        self.interactiveDismissalEnabled = interactiveDismissalEnabled
        self.startingView = startingView
        
        if let endingView = endingView {
            self.resolveEndingView = { [weak self] (photo, index) in
                self?.endingView = endingView(photo, index)
            }
        }
    }
    
    public convenience override init() {
        self.init(interactiveDismissalEnabled: true, startingView: nil, endingView: nil)
    }

}
