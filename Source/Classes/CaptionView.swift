//
//  CaptionView.swift
//  Pods
//
//  Created by Alex Hill on 5/28/17.
//
//

import UIKit

@objc(AXCaptionView) open class CaptionView: UIView, CaptionViewProtocol {
    
    var titleLabel = UILabel()
    var descriptionLabel = UILabel()
    var creditLabel = UILabel()
    
    var defaultTitleAttributes: [String: Any] {
        get {
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
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
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
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
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1,
                                                                          compatibleWith: self.traitCollection)
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
        
        func transitionLabel(_ label: UILabel, hidden: Bool, text: NSAttributedString?) {
            if !hidden {
                label.isHidden = false
            }
            
            UIView.transition(with: label,
                              duration: OverlayTransitionAnimationDuration,
                              options: [.transitionCrossDissolve], animations: {
                label.attributedText = text
            }) { (finished) in
                guard finished && hidden else {
                    return
                }
                
                label.isHidden = true
            }
        }
        
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
        var isLabelHidden = false
        
        let title = makeAttributedStringWithDefaults(self.defaultTitleAttributes, for: attributedTitle)
        isLabelHidden = title?.string.isEmpty ?? true
        transitionLabel(self.titleLabel, hidden: isLabelHidden, text: title)
        if !isLabelHidden {
            self.visibleLabels.append(self.titleLabel)
        }
        
        let description = makeAttributedStringWithDefaults(self.defaultDescriptionAttributes, for: attributedDescription)
        isLabelHidden = description?.string.isEmpty ?? true
        transitionLabel(self.descriptionLabel, hidden: isLabelHidden, text: description)
        if !isLabelHidden {
            self.visibleLabels.append(self.descriptionLabel)
        }
        
        let credit = makeAttributedStringWithDefaults(self.defaultCreditAttributes, for: attributedCredit)
        isLabelHidden = credit?.string.isEmpty ?? true
        transitionLabel(self.creditLabel, hidden: isLabelHidden, text: credit)
        if !isLabelHidden {
            self.visibleLabels.append(self.creditLabel)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.computeSize(for: self.frame.size, applyLayout: true)
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
                
                let newFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: fontTextStyle, compatibleWith: self?.traitCollection)
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
        let InterLabelSpacing: CGFloat = 4
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
        
        return CGSize(width: constrainedSize.width, height: yOffset)
    }

}
