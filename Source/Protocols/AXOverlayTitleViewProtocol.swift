//
//  AXOverlayTitleViewProtocol.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/1/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

#if os(iOS)
@objc public protocol AXOverlayTitleViewProtocol: NSObjectProtocol {
    
    /// This method is called by the `AXOverlayView`'s toolbar in order to size the view appropriately for display.
    @objc func sizeToFit() -> Void
    
    /// Called when swipe progress between photos is updated. This method can be implemented to update your [progressive] 
    /// title view with a new position.
    ///
    /// - Parameters:
    ///   - low: The low photo index that is being swiped. (high - 1)
    ///   - high: The high photo index that is being swiped. (low + 1)
    ///   - percent: The percent swiped between the two indexes.
    @objc optional func tweenBetweenLowIndex(_ low: Int, highIndex high: Int, percent: CGFloat)

}
#endif
