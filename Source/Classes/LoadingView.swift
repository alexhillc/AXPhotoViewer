//
//  LoadingView.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(AXLoadingView) public class LoadingView: UIView, LoadingViewProtocol {
    
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
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let indicatorViewSize = self.indicatorView.sizeThatFits(self.frame.size)
        let errorLabelSize = self.errorLabel?.sizeThatFits(self.frame.size) ?? .zero
        return CGSize(width: max(indicatorViewSize.width, errorLabelSize.width),
                      height: max(indicatorViewSize.height, errorLabelSize.height))
    }
    
    // MARK: - UITapGestureRecognizer
    @objc private func tapAction(_ sender: UITapGestureRecognizer) {
        self.retryHandler?()
        self.retryHandler = nil
    }
    
}
