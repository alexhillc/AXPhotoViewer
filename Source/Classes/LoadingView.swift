//
//  LoadingView.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(AXLoadingView) open class LoadingView: UIView, LoadingViewProtocol {
    
    fileprivate(set) var indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    fileprivate var errorLabel: UILabel?
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?
    fileprivate var retryHandler: (() -> Void)?
    
    public func startLoading(initialProgress: CGFloat) {
        if self.indicatorView.superview == nil {
            self.addSubview(self.indicatorView)
            self.setNeedsLayout()
        }
        
        self.indicatorView.startAnimating()
    }
    
    public func stopLoading() {
        self.indicatorView.stopAnimating()
    }
    
    public func updateProgress(_ progress: CGFloat) {
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
        self.errorLabel?.numberOfLines = 3
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let indicatorViewSize = self.indicatorView.sizeThatFits(self.frame.size)
        self.indicatorView.frame = CGRect(origin: CGPoint(x: (self.frame.size.width - indicatorViewSize.width) / 2,
                                                          y: (self.frame.size.height - indicatorViewSize.height) / 2),
                                          size: indicatorViewSize)
        
        if let errorLabel = self.errorLabel {
            let errorLabelSize = errorLabel.sizeThatFits(self.frame.size)
            errorLabel.frame = CGRect(origin: CGPoint(x: (self.frame.size.width - errorLabelSize.width) / 2,
                                                      y: (self.frame.size.height - errorLabelSize.height) / 2),
                                      size: errorLabelSize)
        }
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let indicatorViewSize = self.indicatorView.sizeThatFits(size)
        let errorLabelSize = self.errorLabel?.sizeThatFits(size) ?? .zero
        return CGSize(width: max(indicatorViewSize.width, errorLabelSize.width),
                      height: max(indicatorViewSize.height, errorLabelSize.height))
    }
    
    // MARK: - UITapGestureRecognizer
    @objc fileprivate func tapAction(_ sender: UITapGestureRecognizer) {
        self.retryHandler?()
        self.retryHandler = nil
    }
    
}
