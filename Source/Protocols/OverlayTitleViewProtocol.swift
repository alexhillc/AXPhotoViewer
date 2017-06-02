//
//  OverlayTitleViewProtocol.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

@objc(AXOverlayTitleViewProtocol) public protocol OverlayTitleViewProtocol: NSObjectProtocol {
    
    /// This method is called by the `OverlayView`'s navigation bar in order to size the view appropriately for display.
    func sizeToFit() -> Void
    
    /// Called when swipe progress between photos is updated. This method can be implemented to update your [progressive] 
    /// title view with a new position.
    ///
    /// - Parameters:
    ///   - low: The low photo index that is being swiped. (high - 1)
    ///   - high: The high photo index that is being swiped. (low + 1)
    ///   - percent: The percent swiped between the two indexes.
    @objc optional func tweenBetweenLowIndex(_ low: Int, highIndex high: Int, percent: CGFloat)

}
