//
//  TransitionInfo.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

@objc(AXTransitionInfo) open class TransitionInfo: NSObject {
    
    fileprivate(set) var referenceRect: CGRect
    fileprivate(set) var referenceView: UIView
    
    var duration: TimeInterval = 0.25
    var interactive: Bool = true
    
    public init(referenceRect: CGRect, referenceView: UIView) {
        self.referenceRect = referenceRect
        self.referenceView = referenceView
        super.init()
    }

}
