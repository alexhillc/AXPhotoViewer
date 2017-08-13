//
//  LoadingView.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/7/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc(AXLoadingView) open class LoadingView: UIView, LoadingViewProtocol {
    
    open fileprivate(set) lazy var indicatorView: UIView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    
    fileprivate var errorLabel: UILabel?
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?
    fileprivate var retryHandler: (() -> Void)?
    
    fileprivate var errorAttributes: [NSAttributedStringKey: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            let font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            let textColor = UIColor.white
            
            return [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.foregroundColor: textColor
            ]
        }
    }
    
    public init() {
        super.init(frame: .zero)
        
        NotificationCenter.default.addObserver(forName: .UIContentSizeCategoryDidChange, object: nil, queue: .main) { [weak self] (note) in
            self?.setNeedsLayout()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let indicatorViewSize = self.indicatorView.sizeThatFits(self.frame.size)
        self.indicatorView.frame = CGRect(origin: CGPoint(x: floor((self.frame.size.width - indicatorViewSize.width) / 2),
                                                          y: floor((self.frame.size.height - indicatorViewSize.height) / 2)),
                                          size: indicatorViewSize)
        
        if let errorLabel = self.errorLabel, let attributedText = errorLabel.attributedText?.mutableCopy() as? NSMutableAttributedString {
            var newAttributedText: NSAttributedString?
            attributedText.enumerateAttribute(NSAttributedStringKey.font,
                                              in: NSMakeRange(0, attributedText.length),
                                              options: [], using: { [weak self] (value, range, stop) in
                guard let oldFont = value as? UIFont else {
                    return
                }
                
                var newFontDescriptor: UIFontDescriptor
                if #available(iOS 10.0, *) {
                    newFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body, compatibleWith: self?.traitCollection)
                } else {
                    newFontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
                }
                
                let newFont = oldFont.withSize(newFontDescriptor.pointSize)
                attributedText.removeAttribute(NSAttributedStringKey.font, range: range)
                attributedText.addAttribute(NSAttributedStringKey.font, value: newFont, range: range)
                newAttributedText = attributedText.copy() as? NSAttributedString
            })
            
            errorLabel.attributedText = newAttributedText
            
            let errorLabelSize = errorLabel.sizeThatFits(self.frame.size)
            errorLabel.frame = CGRect(origin: CGPoint(x: floor((self.frame.size.width - errorLabelSize.width) / 2),
                                                      y: floor((self.frame.size.height - errorLabelSize.height) / 2)),
                                      size: errorLabelSize)
        }
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let indicatorViewSize = self.indicatorView.sizeThatFits(size)
        let errorLabelSize = self.errorLabel?.sizeThatFits(size) ?? .zero
        return CGSize(width: max(indicatorViewSize.width, errorLabelSize.width),
                      height: max(indicatorViewSize.height, errorLabelSize.height))
    }
    
    open func startLoading(initialProgress: CGFloat) {
        if self.indicatorView.superview == nil {
            self.addSubview(self.indicatorView)
            self.setNeedsLayout()
        }
        
        if let indicatorView = self.indicatorView as? UIActivityIndicatorView, !indicatorView.isAnimating {
            indicatorView.startAnimating()
        }
    }
    
    open func stopLoading() {
        if let indicatorView = self.indicatorView as? UIActivityIndicatorView, indicatorView.isAnimating {
            indicatorView.stopAnimating()
        }
    }
    
    open func updateProgress(_ progress: CGFloat) {
        // empty for now, need to create a progressive loading indicator
    }
    
    open func showError(_ error: Error, retryHandler: @escaping () -> Void) {
        self.stopLoading()
        
        self.retryHandler = retryHandler
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        self.addGestureRecognizer(self.tapGestureRecognizer!)
        
        let errorText = NSLocalizedString("An error occurred while loading this image.\nTap to try again.", comment: "")
        
        self.errorLabel = UILabel()
        self.errorLabel?.attributedText = NSAttributedString(string: errorText, attributes: self.errorAttributes)
        self.errorLabel?.textAlignment = .center
        self.errorLabel?.numberOfLines = 3
        self.errorLabel?.textColor = .white
        self.addSubview(self.errorLabel!)
        
        self.setNeedsLayout()
    }
    
    open func removeError() {
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
    
    // MARK: - UITapGestureRecognizer
    @objc fileprivate func tapAction(_ sender: UITapGestureRecognizer) {
        self.retryHandler?()
        self.retryHandler = nil
    }
    
}
