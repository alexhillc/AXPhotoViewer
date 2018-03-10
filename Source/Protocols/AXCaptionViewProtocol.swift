//
//  AXCaptionViewProtocol.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/28/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc public protocol AXCaptionViewProtocol: NSObjectProtocol {
    
    /// Whether or not the `CaptionView` should animate caption info changes - using `Constants.frameAnimDuration` as
    /// the animation duration.
    @objc var animateCaptionInfoChanges: Bool { get set }
    
    /// The `AXPhotosViewController` will call this method when a new photo is ready to have its information displayed.
    /// The implementation should update the `captionView` with the attributed parameters. 
    ///
    /// - Parameters:
    ///   - attributedTitle: The attributed title of the new photo.
    ///   - attributedDescription: The attributed description of the new photo.
    ///   - attributedCredit: The attributed credit of the new photo.
    @objc func applyCaptionInfo(attributedTitle: NSAttributedString?,
                                attributedDescription: NSAttributedString?,
                                attributedCredit: NSAttributedString?)
    
    /// The `AXPhotosViewController` uses this method to correctly size the caption view for a constrained width.
    ///
    /// - Parameter size: The constrained size. Use the width of this value to layout subviews.
    /// - Returns: A size that fits all subviews inside a constrained width.
    @objc func sizeThatFits(_ size: CGSize) -> CGSize
    
}
