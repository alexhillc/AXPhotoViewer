//
//  LoadingView.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(BAPLoadingViewProtocol) public protocol LoadingViewProtocol: NSObjectProtocol {
    
    /// Called by the PhotoViewController when progress of the image download should be shown to the user.
    ///
    /// - Parameter initialProgress: The current progress of the image download.
    func startLoading(initialProgress: Progress) -> Void
    
    /// Called by the PhotoViewController when progress of the image download should be hidden. This usually happens when
    /// the containing view controller is moved offscreen.
    ///
    func stopLoading() -> Void
    
    /// Called by the PhotoViewController when the progress of an image download is updated. The optional implementation 
    /// of this method should reflect the progress of the downloaded image.
    ///
    /// - Parameter progress: The progress complete of the image download.
    @objc optional func updateProgress(_ progress: Progress) -> Void
    
    /// Called by the PhotoViewController when an image download fails. The implementation of this method should display
    /// an error to the user, and optionally, offer to retry the image download.
    ///
    /// - Parameters:
    ///   - error: The error that the image download failed with.
    ///   - retryHandler: Call this handler to retry the image download.
    func showError(_ error: Error, retryHandler: @escaping ()-> Void) -> Void
    
    /// Called by the PhotoViewController when an image download is being retried, or the container decides to stop
    /// displaying an error to the user.
    ///
    func removeError() -> Void
    
}

@objc(BAPLoadingView) public class LoadingView: UIView, LoadingViewProtocol {
    
    private(set) var indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    private var errorLabel: UILabel?
    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var retryHandler: (() -> Void)?
    
    public func startLoading(initialProgress: Progress) {
        if self.indicatorView.superview == nil {
            self.addSubview(self.indicatorView)
            self.setNeedsLayout()
        }
        
        self.indicatorView.startAnimating()
    }
    
    public func stopLoading() {
        self.indicatorView.stopAnimating()
    }
    
    public func updateProgress(_ progress: Progress) {
        // empty for now, need to create a progressive loading indicator
    }
    
    public func showError(_ error: Error, retryHandler: @escaping () -> Void) {
        self.stopLoading()
        
        self.retryHandler = retryHandler
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        self.addGestureRecognizer(self.tapGestureRecognizer!)
        
        self.errorLabel = UILabel()
        self.errorLabel?.text = NSLocalizedString("An error occurred while loading this image.\nTap to try again.", comment: "")
        self.errorLabel?.textAlignment = .center
        self.errorLabel?.numberOfLines = 2
        self.errorLabel?.textColor = .white
        self.addSubview(self.errorLabel!)
        
        self.setNeedsLayout()
    }
    
    public func removeError() {
        if let tapGestureRecognizer = self.tapGestureRecognizer {
            self.removeGestureRecognizer(tapGestureRecognizer)
            self.tapGestureRecognizer = nil
        }
        
        if let errorLabel = self.errorLabel {
            errorLabel.removeFromSuperview()
            self.errorLabel = nil
        }
        
        self.retryHandler = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.indicatorView.sizeToFit()
        self.indicatorView.frame = CGRect(origin: CGPoint(x: (self.frame.size.width - self.indicatorView.frame.size.width) / 2,
                                                          y: (self.frame.size.height - self.indicatorView.frame.size.height) / 2),
                                          size: self.indicatorView.frame.size)
        
        if let errorLabel = self.errorLabel {
            errorLabel.sizeToFit()
            errorLabel.frame = CGRect(origin: CGPoint(x: (self.frame.size.width - errorLabel.frame.size.width) / 2,
                                                      y: (self.frame.size.height - errorLabel.frame.size.height) / 2),
                                      size: errorLabel.frame.size)
        }
    }
    
    // MARK: - UITapGestureRecognizer
    @objc private func tapAction(_ sender: UITapGestureRecognizer) {
        self.retryHandler?()
        self.retryHandler = nil
    }
    
}
