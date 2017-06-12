//
//  TransitionInfo.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

@objc(AXTransitionInfo) open class TransitionInfo: NSObject {
    
    fileprivate(set) weak var referenceView: UIImageView?
    
    var duration: TimeInterval = 0.35
    var interactive: Bool = true
    
    public init(referenceView: UIImageView?) {
        self.referenceView = referenceView
        super.init()
    }

}
