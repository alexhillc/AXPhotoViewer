//
//  CaptionViewProtocol.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/28/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc(AXCaptionViewProtocol) public protocol CaptionViewProtocol: NSObjectProtocol {
    
    /// The delegate used by the framework to respond to content size changes.
    weak var delegate: CaptionViewDelegate? { get set }
    
    /// Whether or not the `CaptionView` should animate caption info changes - using `AXConstants.frameAnimDuration` as
    /// the animation duration.
    var animateCaptionInfoChanges: Bool { get set }
    
    /// The `PhotosViewController` will call this method when a new photo is ready to have its information displayed.
    /// The implementation should update the `captionView` with the attributed parameters. 
    ///
    /// - Parameters:
    ///   - attributedTitle: The attributed title of the new photo.
    ///   - attributedDescription: The attributed description of the new photo.
    ///   - attributedCredit: The attributed credit of the new photo.
    func applyCaptionInfo(attributedTitle: NSAttributedString?,
                          attributedDescription: NSAttributedString?,
                          attributedCredit: NSAttributedString?)
    
    /// The `PhotosViewController` uses this method to correctly size the caption view for a constrained width.
    ///
    /// - Parameter size: The constrained size. Use the width of this value to layout subviews.
    /// - Returns: A size that fits all subviews inside a constrained width.
    func sizeThatFits(_ size: CGSize) -> CGSize
    
}

@objc(AXCaptionViewDelegate) public protocol CaptionViewDelegate: AnyObject, NSObjectProtocol {
    
    /// This method should be called when the size of the content inside of your view changes. This notifies the containing
    /// view that it should update its layout to accomodate the content size change.
    ///
    /// - Parameters:
    ///   - captionView: The `captionView` whose content size changed.
    ///   - newSize: The new content size of the `captionView`.
    @objc(captionView:contentSizeDidChange:)
    func captionView(_ captionView: CaptionViewProtocol, contentSizeDidChange newSize: CGSize) -> Void
    
}
