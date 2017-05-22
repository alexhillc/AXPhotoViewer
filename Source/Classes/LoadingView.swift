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
    
}

@objc(BAPLoadingView) public class LoadingView: UIView, LoadingViewProtocol {
    
    public func updateProgress(_ progress: Progress) {
        
    }
    
}
