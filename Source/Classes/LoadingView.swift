//
//  LoadingView.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(BAPLoadingViewProtocol) public protocol LoadingViewProtocol: NSObjectProtocol {
    
    /// Called by the PhotoViewController when the progress of an image download is updated. The optional implementation 
    /// of this method should reflect the progress of the downloaded image.
    ///
    /// - Parameter progress: The progress complete of the image download.
    @objc optional func updateProgress(_ progress: Progress)
    
    /// Called by the PhotoViewController when an image download fails. The implementation of this method should display
    /// an error to the user, and optionally, offer to retry the image download.
    ///
    /// - Parameters:
    ///   - error: The error that the image download failed with.
    ///   - retryHandler: Call this handler to retry the image download.
    func showError(_ error: Error, retryHandler: ()-> Void)
    
}

@objc(BAPLoadingView) public class LoadingView: UIView, LoadingViewProtocol {
    
    public func updateProgress(_ progress: Progress) {
        
    }
    
    public func showError(_ error: Error, retryHandler: () -> Void) {
        
    }
    
}
