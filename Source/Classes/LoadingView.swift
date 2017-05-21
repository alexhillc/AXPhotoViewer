//
//  LoadingView.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(BAPLoadingViewProtocol) protocol LoadingViewProtocol: NSObjectProtocol {
    
    /// Called by the PhotoViewController when the progress of an image download is updated. The optional implementation 
    /// of this method should reflect the progress of the downloaded image.
    ///
    /// - Parameter percentComplete: The percent complete of the image download (0..<1)
    @objc optional func updateProgress(percent: Double)
    
}

@objc(BAPLoadingView) class LoadingView: UIView, LoadingViewProtocol {
    
    func updateProgress(percent: Double) {
        
    }
    
}
