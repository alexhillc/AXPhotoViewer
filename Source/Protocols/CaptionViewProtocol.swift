//
//  CaptionViewProtocol.swift
//  Pods
//
//  Created by Alex Hill on 5/28/17.
//
//

@objc(BAPCaptionViewProtocol) public protocol CaptionViewProtocol: NSObjectProtocol {
    
    /// The `PhotosViewController` will call this method when a new photo is ready to have its information displayed.
    /// The implementation should update the `captionView` with the attributed parameters. 
    ///
    /// - Parameters:
    ///   - attributedTitle: The attributed title of the new photo.
    ///   - attributedDescription: The attributed description of the new photo.
    ///   - attributedCredit: The attributed credit of the new photo.
    /// - Important: This method should NOT perform any layout.
    func applyCaptionInfo(attributedTitle: NSAttributedString?,
                          attributedDescription: NSAttributedString?,
                          attributedCredit: NSAttributedString?)
    
    /// The `PhotosViewController` uses this method to correctly size the caption view for a constrained width.
    ///
    /// - Parameter size: The constrained size. Use the width of this value to layout subviews.
    /// - Returns: A size that fits all subviews inside a constrained width.
    func sizeThatFits(_ size: CGSize) -> CGSize
    
}
