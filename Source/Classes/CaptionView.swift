//
//  CaptionView.swift
//  Pods
//
//  Created by Alex Hill on 5/28/17.
//
//

import UIKit

@objc(AXCaptionView) open class CaptionView: UIView, CaptionViewProtocol {
    
    public weak var delegate: CaptionViewDelegate?
    
    var titleLabel = UILabel()
    var descriptionLabel = UILabel()
    var creditLabel = UILabel()
    
    fileprivate var needsUpdateContentSize = false

    fileprivate let CaptionAnimDuration: TimeInterval = 0.20
    open override var frame: CGRect {
        set(value) {
            let animation: () -> Void = { super.frame = value }
            
            if self.isFirstLayout {
                animation()
            } else {
                UIView.animate(withDuration: CaptionAnimDuration, delay: 0, options: [.curveEaseOut], animations: animation, completion: nil)
            }
        }
        get {
            return super.frame
        }
    }
    
    fileprivate var isFirstLayout: Bool = true
    
    var defaultTitleAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            let font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFontWeightBold)
            let textColor = UIColor.white
            
            return [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor
            ]
        }
    }
    
    var defaultDescriptionAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                              compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            let font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFontWeightLight)
            let textColor = UIColor.lightGray
            
            return [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor
            ]
        }
    }
    
    var defaultCreditAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .caption1).fontDescriptor
            }
            
            let font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFontWeightLight)
            let textColor = UIColor.gray
            
            return [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor
            ]
        }
    }
    
    fileprivate var visibleLabels: [UILabel]
    
    init() {
        self.visibleLabels = [
            self.titleLabel,
            self.descriptionLabel,
            self.creditLabel
        ]

        super.init(frame: .zero)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        self.titleLabel.textColor = .white
        self.titleLabel.numberOfLines = 0
        self.addSubview(self.titleLabel)
        
        self.descriptionLabel.textColor = .white
        self.descriptionLabel.numberOfLines = 0
        self.addSubview(self.descriptionLabel)
        
        self.creditLabel.textColor = .white
        self.creditLabel.numberOfLines = 0
        self.addSubview(self.creditLabel)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func applyCaptionInfo(attributedTitle: NSAttributedString?,
                          attributedDescription: NSAttributedString?,
                          attributedCredit: NSAttributedString?) {
        
        func makeAttributedStringWithDefaults(_ defaults: [String: Any], for attributedString: NSAttributedString?) -> NSAttributedString? {
            guard let defaultAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else {
                return attributedString
            }
            
            var containsAttributes = false
            defaultAttributedString.enumerateAttributes(in: NSMakeRange(0, defaultAttributedString.length), options: []) { (attributes, range, stop) in
                guard attributes.count > 0 else {
                    return
                }
                
                containsAttributes = true
                stop.pointee = true
            }
            
            guard !containsAttributes else {
                return attributedString
            }
            
            defaultAttributedString.addAttributes(defaults, range: NSMakeRange(0, defaultAttributedString.length))
            return defaultAttributedString
        }
        
        self.visibleLabels = []
        
        let title = makeAttributedStringWithDefaults(self.defaultTitleAttributes, for: attributedTitle)
        let description = makeAttributedStringWithDefaults(self.defaultDescriptionAttributes, for: attributedDescription)
        let credit = makeAttributedStringWithDefaults(self.defaultCreditAttributes, for: attributedCredit)

        self.titleLabel.alpha = 1
        self.descriptionLabel.alpha = 1
        self.creditLabel.alpha = 1
        
        let animateOut: () -> Void = { [weak self] in
            self?.titleLabel.alpha = 0
            self?.descriptionLabel.alpha = 0
            self?.creditLabel.alpha = 0
        }
        
        let animateOutCompletion: (_ finished: Bool) -> Void = { [weak self] (finished) in
            guard let uSelf = self, finished else {
                return
            }
            
            uSelf.titleLabel.attributedText = title
            uSelf.descriptionLabel.attributedText = description
            uSelf.creditLabel.attributedText = credit
            
            if uSelf.titleLabel.attributedText?.string.isEmpty ?? true {
                uSelf.titleLabel.isHidden = true
            } else {
                uSelf.titleLabel.isHidden = false
                uSelf.visibleLabels.append(uSelf.titleLabel)
            }
            
            if uSelf.descriptionLabel.attributedText?.string.isEmpty ?? true {
                uSelf.descriptionLabel.isHidden = true
            } else {
                uSelf.descriptionLabel.isHidden = false
                uSelf.visibleLabels.append(uSelf.descriptionLabel)
            }
            
            if uSelf.creditLabel.attributedText?.string.isEmpty ?? true {
                uSelf.creditLabel.isHidden = true
            } else {
                uSelf.creditLabel.isHidden = false
                uSelf.visibleLabels.append(uSelf.creditLabel)
            }
            
            uSelf.setNeedsUpdateContentSize()
        }
        
        let animateIn: () -> Void = { [weak self] in
            self?.titleLabel.alpha = 1
            self?.descriptionLabel.alpha = 1
            self?.creditLabel.alpha = 1
        }
        
        if self.isFirstLayout {
            animateOut()
            animateOutCompletion(true)
            animateIn()
        } else {
            UIView.animate(withDuration: CaptionAnimDuration / 2, delay: 0, options: [.curveEaseOut], animations: animateOut) { [weak self] (finished) in
                guard let uSelf = self else {
                    return
                }
                
                animateOutCompletion(finished)
                UIView.animate(withDuration: uSelf.CaptionAnimDuration / 2, delay: 0, options: [.curveEaseIn], animations: animateIn)
            }
        }
    }
    
    fileprivate func setNeedsUpdateContentSize() {
        self.needsUpdateContentSize = true
        self.setNeedsLayout()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.computeSize(for: self.frame.size, applyLayout: true)
        self.isFirstLayout = false
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applyLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applyLayout: Bool) -> CGSize {
        func makeFontAdjustedAttributedString(for attributedString: NSAttributedString?, fontTextStyle: UIFontTextStyle) -> NSAttributedString? {
            guard let fontAdjustedAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else {
                return attributedString
            }
            
            fontAdjustedAttributedString.enumerateAttribute(NSFontAttributeName,
                                                            in: NSMakeRange(0, fontAdjustedAttributedString.length),
                                                            options: [], using: { [weak self] (value, range, stop) in
                guard let oldFont = value as? UIFont else {
                    return
                }
                
                var newFontDescriptor: UIFontDescriptor
                if #available(iOS 10.0, *) {
                    newFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: fontTextStyle, compatibleWith: self?.traitCollection)
                } else {
                    newFontDescriptor = UIFont.preferredFont(forTextStyle: fontTextStyle).fontDescriptor
                }
                                                                
                let newFont = oldFont.withSize(newFontDescriptor.pointSize)
                fontAdjustedAttributedString.removeAttribute(NSFontAttributeName, range: range)
                fontAdjustedAttributedString.addAttribute(NSFontAttributeName, value: newFont, range: range)
            })
            
            return fontAdjustedAttributedString.copy() as? NSAttributedString
        }

        self.titleLabel.attributedText = makeFontAdjustedAttributedString(for: self.titleLabel.attributedText, fontTextStyle: .body)
        self.descriptionLabel.attributedText = makeFontAdjustedAttributedString(for: self.descriptionLabel.attributedText, fontTextStyle: .body)
        self.creditLabel.attributedText = makeFontAdjustedAttributedString(for: self.creditLabel.attributedText, fontTextStyle: .caption1)
        
        let VerticalPadding: CGFloat = 10
        let HorizontalPadding: CGFloat = 15
        let InterLabelSpacing: CGFloat = 2
        var yOffset: CGFloat = 0

        for (index, label) in self.visibleLabels.enumerated() {
            var constrainedLabelSize = constrainedSize
            constrainedLabelSize.width -= (2 * HorizontalPadding)
            
            let labelSize = label.sizeThatFits(constrainedLabelSize)

            if index == 0 {
                yOffset += VerticalPadding
            } else {
                yOffset += InterLabelSpacing
            }
            
            let labelFrame = CGRect(origin: CGPoint(x: HorizontalPadding,
                                                    y: yOffset),
                                    size: labelSize)
            
            yOffset += labelFrame.size.height
            if index == (self.visibleLabels.count - 1) {
                yOffset += VerticalPadding
            }
            
            if applyLayout {
                label.frame = labelFrame
            }
        }
        
        let sizeThatFits = CGSize(width: constrainedSize.width, height: yOffset)
        
        if self.needsUpdateContentSize {
            self.delegate?.captionView(self, contentSizeDidChange: sizeThatFits)
            self.needsUpdateContentSize = false
        }
        
        return sizeThatFits
    }

}
