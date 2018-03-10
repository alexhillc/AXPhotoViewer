//
//  AXLoadingViewProtocol.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/28/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc public protocol AXLoadingViewProtocol: NSObjectProtocol {
    
    /// Called by the AXPhotoViewController when progress of the image download should be shown to the user.
    ///
    /// - Parameter initialProgress: The current progress of the image download. Exists on a scale from 0..1.
    @objc func startLoading(initialProgress: CGFloat) -> Void
    
    /// Called by the AXPhotoViewController when progress of the image download should be hidden. This usually happens when
    /// the containing view controller is moved offscreen.
    ///
    @objc func stopLoading() -> Void
    
    /// Called by the AXPhotoViewController when the progress of an image download is updated. The optional implementation
    /// of this method should reflect the progress of the downloaded image.
    ///
    /// - Parameter progress: The progress complete of the image download. Exists on a scale from 0..1.
    @objc optional func updateProgress(_ progress: CGFloat) -> Void
    
    /// Called by the AXPhotoViewController when an image download fails. The implementation of this method should display
    /// an error to the user, and optionally, offer to retry the image download.
    ///
    /// - Parameters:
    ///   - error: The error that the image download failed with.
    ///   - retryHandler: Call this handler to retry the image download.
    @objc func showError(_ error: Error, retryHandler: @escaping ()-> Void) -> Void
    
    /// Called by the AXPhotoViewController when an image download is being retried, or the container decides to stop
    /// displaying an error to the user.
    ///
    @objc func removeError() -> Void
    
    /// The `AXPhotosViewController` uses this method to correctly size the loading view for a constrained width.
    ///
    /// - Parameter size: The constrained size. Use the width of this value to layout subviews.
    /// - Returns: A size that fits all subviews inside a constrained width.
    @objc func sizeThatFits(_ size: CGSize) -> CGSize
    
}
