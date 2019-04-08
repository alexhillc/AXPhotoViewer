//
//  AXLoadingView.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/7/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc open class AXLoadingView: UIView, AXLoadingViewProtocol {
    
    #if os(iOS)
    @objc open fileprivate(set) var retryButton: AXButton?
    
    /// The error text to show inside of the `retryButton` when displaying an error.
    @objc open var retryText: String {
        return NSLocalizedString("Try again", comment: "AXLoadingView - retry text")
    }
    
    /// The attributes that will get applied to the `retryText` when displaying an error.
    @objc open var retryAttributes: [NSAttributedString.Key: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, tvOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            var font: UIFont
            if #available(iOS 8.2, *) {
                font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            } else {
                font = UIFont(name: "HelveticaNeue-Light", size: fontDescriptor.pointSize)!
            }
            
            return [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        }
    }
    
    @objc public fileprivate(set) var retryHandler: (() -> Void)?
    #endif
    
    @objc open fileprivate(set) lazy var indicatorView: UIView = UIActivityIndicatorView(style: .white)
    
    @objc open fileprivate(set) var errorImageView: UIImageView?
    
    /// The image to show in the `errorImageView` when displaying an error.
    @objc open var errorImage: UIImage? {
        get {
            return UIImage(named: "axphotoviewer-error", in: AXBundle.frameworkBundle, compatibleWith: nil)
        }
    }
    
    @objc open fileprivate(set) var errorLabel: UILabel?
    
    /// The error text to show when displaying an error.
    @objc open var errorText: String {
        get {
            return NSLocalizedString("An error occurred while loading this image.", comment: "AXLoadingView - error text")
        }
    }
    
    /// The attributes that will get applied to the `errorText` when displaying an error.
    @objc open var errorAttributes: [NSAttributedString.Key: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, tvOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            var font: UIFont
            if #available(iOS 8.2, *) {
                font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            } else {
                font = UIFont(name: "HelveticaNeue-Light", size: fontDescriptor.pointSize)!
            }
            
            return [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        }
    }
    
    @objc public init() {
        super.init(frame: .zero)
        
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] (note) in
            self?.setNeedsLayout()
        }
    }
    
    @objc public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.computeSize(for: self.frame.size, applySizingLayout: true)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applySizingLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applySizingLayout: Bool) -> CGSize {
        func makeAttributedStringWithAttributes(_ attributes: [NSAttributedString.Key: Any], for attributedString: NSAttributedString?) -> NSAttributedString? {
            guard let newAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else { return attributedString }
            newAttributedString.setAttributes(nil, range: NSMakeRange(0, newAttributedString.length))
            newAttributedString.addAttributes(attributes, range: NSMakeRange(0, newAttributedString.length))
            return newAttributedString.copy() as? NSAttributedString
        }
        
        let ImageViewVerticalPadding: CGFloat = 20
        let VerticalPadding: CGFloat = 10
        var totalHeight: CGFloat = 0
        
        var indicatorViewSize: CGSize = .zero
        var errorImageViewSize: CGSize = .zero
        var errorLabelSize: CGSize = .zero
        var retryButtonSize: CGSize = .zero
        if let errorLabel = self.errorLabel {
            if let errorImageView = self.errorImageView {
                errorImageViewSize = errorImageView.sizeThatFits(constrainedSize)
                totalHeight += errorImageViewSize.height
                totalHeight += ImageViewVerticalPadding
            }
            
            errorLabel.attributedText = makeAttributedStringWithAttributes(self.errorAttributes, for: errorLabel.attributedText)
            
            errorLabelSize = errorLabel.sizeThatFits(constrainedSize)
            totalHeight += errorLabelSize.height
            
            // on iOS, we want the button to be sized to its label,
            // on tvOS, we want the button to be sized to its original size for the focus effect
            #if os(iOS)
            if let retryButton = self.retryButton {
                retryButton.setAttributedTitle(makeAttributedStringWithAttributes(self.retryAttributes,
                                                                                  for: retryButton.attributedTitle(for: .normal)),
                                               for: .normal)
                
                let RetryButtonLabelPadding: CGFloat = 10.0
                retryButtonSize = retryButton.titleLabel?.sizeThatFits(constrainedSize) ?? .zero
                retryButtonSize.width += RetryButtonLabelPadding
                retryButtonSize.height += RetryButtonLabelPadding
                totalHeight += retryButtonSize.height
                totalHeight += VerticalPadding
            }
            #endif
        } else {
            indicatorViewSize = self.indicatorView.sizeThatFits(constrainedSize)
            totalHeight += indicatorViewSize.height
        }
        
        if applySizingLayout {
            var yOffset: CGFloat = (constrainedSize.height - totalHeight) / 2.0
            
            if let errorLabel = self.errorLabel {
                if let errorImageView = self.errorImageView {
                    errorImageView.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - errorImageViewSize.width) / 2),
                                                                  y: floor(yOffset)),
                                                  size: errorImageViewSize)
                    yOffset += errorImageViewSize.height
                    yOffset += ImageViewVerticalPadding
                }
                
                errorLabel.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - errorLabelSize.width) / 2),
                                                          y: floor(yOffset)),
                                          size: errorLabelSize)
                
                #if os(iOS)
                if let retryButton = self.retryButton {
                    yOffset += errorLabelSize.height
                    yOffset += VerticalPadding
                    
                    retryButton.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - retryButtonSize.width) / 2),
                                                               y: floor(yOffset)),
                                               size: retryButtonSize)
                    retryButton.setCornerRadius(retryButtonSize.height / 4.0, for: .normal)
                }
                #endif
            } else {
                self.indicatorView.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - indicatorViewSize.width) / 2),
                                                                  y: floor(yOffset)),
                                                  size: indicatorViewSize)
            }
        }
        
        return CGSize(width: constrainedSize.width, height: totalHeight)
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
        
        if let errorImage = self.errorImage {
            self.errorImageView = UIImageView(image: errorImage)
            self.errorImageView?.tintColor = .white
            self.addSubview(self.errorImageView!)
        } else {
            self.errorImageView?.removeFromSuperview()
            self.errorImageView = nil
        }
        
        self.errorLabel = UILabel()
        self.errorLabel?.attributedText = NSAttributedString(string: self.errorText, attributes: self.errorAttributes)
        self.errorLabel?.textAlignment = .center
        self.errorLabel?.numberOfLines = 3
        self.errorLabel?.textColor = .white
        self.addSubview(self.errorLabel!)
        
        #if os(iOS)
        self.retryHandler = retryHandler
        	
        self.retryButton = AXButton()
        self.retryButton?.setAttributedTitle(NSAttributedString(string: self.retryText, attributes: self.retryAttributes),
                                             for: .normal)
        self.retryButton?.addTarget(self, action: #selector(retryButtonAction(_:)), for: .touchUpInside)
        self.addSubview(self.retryButton!)
        #endif
        
        self.setNeedsLayout()
    }
    
    open func removeError() {
        if let errorImageView = self.errorImageView {
            errorImageView.removeFromSuperview()
            self.errorImageView = nil
        }
        
        if let errorLabel = self.errorLabel {
            errorLabel.removeFromSuperview()
            self.errorLabel = nil
        }
        
        #if os(iOS)
        if let retryButton = self.retryButton {
            retryButton.removeFromSuperview()
            self.retryButton = nil
        }
        
        self.retryHandler = nil
        #endif
    }
    
    #if os(iOS)
    // MARK: - Button actions
    @objc fileprivate func retryButtonAction(_ sender: AXButton) {
        self.retryHandler?()
        self.retryHandler = nil
    }
    #endif
    
}
