//
//  AXCaptionView.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/28/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit

@objc open class AXCaptionView: UIView, AXCaptionViewProtocol {
        
    @objc public var animateCaptionInfoChanges: Bool = true
    
    @objc open var titleLabel = UILabel()
    @objc open var descriptionLabel = UILabel()
    @objc open var creditLabel = UILabel()
    
    fileprivate var titleSizingLabel = UILabel()
    fileprivate var descriptionSizingLabel = UILabel()
    fileprivate var creditSizingLabel = UILabel()
    
    fileprivate var visibleLabels: [UILabel]
    fileprivate var visibleSizingLabels: [UILabel]
    
    fileprivate var needsCaptionLayoutAnim = false
    fileprivate var isCaptionAnimatingIn = false
    fileprivate var isCaptionAnimatingOut = false
    
    fileprivate var didOverwriteDefaultTitleFontAttributes = false
    fileprivate var didOverwriteDefaultDescriptionFontAttributes = false
    fileprivate var didOverwriteDefaultCreditFontAttributes = false
    
    fileprivate var isFirstLayout: Bool = true
    
    @objc open var defaultTitleAttributes: [NSAttributedString.Key: Any] {
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
                font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.bold)
            } else {
                font = UIFont(name: "HelveticaNeue-Bold", size: fontDescriptor.pointSize)!
            }
            
            return [
                .font: font,
                .foregroundColor: UIColor.white
            ]
        }
    }
    
    @objc open var defaultDescriptionAttributes: [NSAttributedString.Key: Any] {
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
                .font: font,
                .foregroundColor: UIColor.lightGray
            ]
        }
    }
    
    @objc open var defaultCreditAttributes: [NSAttributedString.Key: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, tvOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .caption1).fontDescriptor
            }
            
            var font: UIFont
            if #available(iOS 8.2, *) {
                font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            } else {
                font = UIFont(name: "HelveticaNeue-Light", size: fontDescriptor.pointSize)!
            }
            
            return [
                .font: font,
                .foregroundColor: UIColor.gray
            ]
        }
    }
    
    @objc public init() {
        self.visibleLabels = [
            self.titleLabel,
            self.descriptionLabel,
            self.creditLabel
        ]
        self.visibleSizingLabels = [
            self.titleSizingLabel,
            self.descriptionSizingLabel,
            self.creditSizingLabel
        ]

        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        self.titleSizingLabel.numberOfLines = 0
        self.descriptionSizingLabel.numberOfLines = 0
        self.creditSizingLabel.numberOfLines = 0
        
        self.titleLabel.textColor = .white
        self.titleLabel.numberOfLines = 0
        self.addSubview(self.titleLabel)
        
        self.descriptionLabel.textColor = .white
        self.descriptionLabel.numberOfLines = 0
        self.addSubview(self.descriptionLabel)
        
        self.creditLabel.textColor = .white
        self.creditLabel.numberOfLines = 0
        self.addSubview(self.creditLabel)
        
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] (note) in
            self?.setNeedsLayout()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc open func applyCaptionInfo(attributedTitle: NSAttributedString?,
                                     attributedDescription: NSAttributedString?,
                                     attributedCredit: NSAttributedString?) {
        var didOverwriteDefaultTitleFontAttributes = false
        var didOverwriteDefaultDescriptionFontAttributes = false
        var didOverwriteDefaultCreditFontAttributes = false
        
        var title = NSAttributedString()
        if let attributedTitle = attributedTitle {
            let result = makeAttributedStringWithDefaults(
                self.defaultTitleAttributes,
                for: attributedTitle
            )
            title = result.attributedString
            didOverwriteDefaultTitleFontAttributes = result.removedDefaultKeys.contains(.font)
        }
        
        var description = NSAttributedString()
        if let attributedDescription = attributedDescription {
            let result = makeAttributedStringWithDefaults(
                self.defaultDescriptionAttributes,
                for: attributedDescription
            )
            description = result.attributedString
            didOverwriteDefaultDescriptionFontAttributes = result.removedDefaultKeys.contains(.font)
        }
        
        var credit = NSAttributedString()
        if let attributedCredit = attributedCredit {
            let result = makeAttributedStringWithDefaults(
                self.defaultCreditAttributes,
                for: attributedCredit
            )
            credit = result.attributedString
            didOverwriteDefaultCreditFontAttributes = result.removedDefaultKeys.contains(.font)
        }
        
        self.didOverwriteDefaultTitleFontAttributes = didOverwriteDefaultTitleFontAttributes
        self.didOverwriteDefaultDescriptionFontAttributes = didOverwriteDefaultDescriptionFontAttributes
        self.didOverwriteDefaultCreditFontAttributes = didOverwriteDefaultCreditFontAttributes
        
        self.visibleSizingLabels = []
        self.visibleLabels = []

        self.titleSizingLabel.attributedText = title
        if !title.string.isEmpty {
            self.visibleSizingLabels.append(self.titleSizingLabel)
            self.visibleLabels.append(self.titleLabel)
        }
        
        self.descriptionSizingLabel.attributedText = description
        if !description.string.isEmpty {
            self.visibleSizingLabels.append(self.descriptionSizingLabel)
            self.visibleLabels.append(self.descriptionLabel)
        }
        
        self.creditSizingLabel.attributedText = credit
        if !credit.string.isEmpty {
            self.visibleSizingLabels.append(self.creditSizingLabel)
            self.visibleLabels.append(self.creditLabel)
        }
        
        self.needsCaptionLayoutAnim = !self.isFirstLayout
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        self.computeSize(for: self.frame.size, applySizingLayout: true)
        
        weak var weakSelf = self
        func applySizingAttributes() {
            guard let `self` = weakSelf else { return }
            
            self.titleLabel.attributedText = self.titleSizingLabel.attributedText
            self.titleLabel.frame = self.titleSizingLabel.frame
            self.titleLabel.isHidden = (self.titleSizingLabel.attributedText?.string.isEmpty ?? true)
            
            self.descriptionLabel.attributedText = self.descriptionSizingLabel.attributedText
            self.descriptionLabel.frame = self.descriptionSizingLabel.frame
            self.descriptionLabel.isHidden = (self.descriptionSizingLabel.attributedText?.string.isEmpty ?? true)
            
            self.creditLabel.attributedText = self.creditSizingLabel.attributedText
            self.creditLabel.frame = self.creditSizingLabel.frame
            self.creditLabel.isHidden = (self.creditSizingLabel.attributedText?.string.isEmpty ?? true)
        }
        
        if self.animateCaptionInfoChanges && self.needsCaptionLayoutAnim {
            // ensure that this block runs in its own animation context (container may animate)
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                let animateOut: () -> Void = {
                    self.titleLabel.alpha = 0
                    self.descriptionLabel.alpha = 0
                    self.creditLabel.alpha = 0
                }
                
                let animateOutCompletion: (_ finished: Bool) -> Void = { (finished) in
                    if !finished {
                        return
                    }
                    
                    applySizingAttributes()
                    self.isCaptionAnimatingOut = false
                }
                
                let animateIn: () -> Void = {
                    self.titleLabel.alpha = 1
                    self.descriptionLabel.alpha = 1
                    self.creditLabel.alpha = 1
                }
                
                let animateInCompletion: (_ finished: Bool) -> Void = { (finished) in
                    if !finished {
                        return
                    }
                    
                    self.isCaptionAnimatingIn = false
                }
                
                if self.isCaptionAnimatingOut {
                    return
                }
                
                self.isCaptionAnimatingOut = true
                UIView.animate(withDuration: AXConstants.frameAnimDuration / 2,
                               delay: 0,
                               options: [.beginFromCurrentState, .curveEaseOut],
                               animations: animateOut) { (finished) in
                    if self.isCaptionAnimatingIn {
                        return
                    }
                    
                    animateOutCompletion(finished)
                    UIView.animate(withDuration: AXConstants.frameAnimDuration / 2,
                                   delay: 0,
                                   options: [.beginFromCurrentState, .curveEaseIn],
                                   animations: animateIn,
                                   completion: animateInCompletion)
                }
            }
            
            self.needsCaptionLayoutAnim = false
            
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                if !self.isCaptionAnimatingOut && !self.isCaptionAnimatingIn {
                    applySizingAttributes()
                }
            }
        }
        
        self.isFirstLayout = false
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applySizingLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize,
                                                    applySizingLayout: Bool) -> CGSize {
        if !self.didOverwriteDefaultTitleFontAttributes {
            self.titleSizingLabel.attributedText = makeFontAdjustedAttributedString(
                for: self.titleSizingLabel.attributedText,
                fontTextStyle: .body
            )
        }
        
        if !self.didOverwriteDefaultDescriptionFontAttributes {
            self.descriptionSizingLabel.attributedText = makeFontAdjustedAttributedString(
                for: self.descriptionSizingLabel.attributedText,
                fontTextStyle: .body
            )
        }
        
        if !self.didOverwriteDefaultCreditFontAttributes {
            self.creditSizingLabel.attributedText = makeFontAdjustedAttributedString(
                for: self.creditSizingLabel.attributedText,
                fontTextStyle: .caption1
            )
        }
        
        #if os(iOS)
        let TopPadding: CGFloat = 10
        let BottomPadding: CGFloat = 10
        let HorizontalPadding: CGFloat = 15
        let InterLabelSpacing: CGFloat = 2
        #else
        let TopPadding: CGFloat = 30
        let BottomPadding: CGFloat = 0
        let HorizontalPadding: CGFloat = 0
        let InterLabelSpacing: CGFloat = 2
        #endif
        
        let xOffset = HorizontalPadding
        var yOffset: CGFloat = 0
        
        for (index, label) in self.visibleSizingLabels.enumerated() {
            var constrainedLabelSize = constrainedSize
            constrainedLabelSize.width -= (2 * HorizontalPadding)
            
            let labelSize = label.sizeThatFits(constrainedLabelSize)
            
            if index == 0 {
                yOffset += TopPadding
            } else {
                yOffset += InterLabelSpacing
            }
            
            let labelFrame = CGRect(
                x: xOffset,
                y: yOffset,
                width: constrainedLabelSize.width,
                height: labelSize.height
            )
            
            yOffset += labelFrame.size.height
            if index == (self.visibleSizingLabels.count - 1) {
                yOffset += BottomPadding
            }
            
            if applySizingLayout {
                label.frame = labelFrame
            }
        }
        
        return CGSize(width: constrainedSize.width, height: yOffset)
    }
    
    // MARK: - Helpers
    private func makeAttributedStringWithDefaults(_ defaults: [NSAttributedString.Key: Any],
                                                  for attributedString: NSAttributedString) -> (attributedString: NSAttributedString,
                                                                                                removedDefaultKeys: Set<NSAttributedString.Key>) {
        guard let defaultAttributedString = attributedString.mutableCopy() as? NSMutableAttributedString else { return (attributedString, []) }
        
        var removedKeys = Set<NSAttributedString.Key>()
        var defaultAttributes = defaults
        defaultAttributedString.enumerateAttributes(in: NSMakeRange(0, defaultAttributedString.length), options: []) { (attributes, range, stop) in
            for key in attributes.keys where defaultAttributes[key] != nil {
                defaultAttributes.removeValue(forKey: key)
                removedKeys.insert(key)
            }
        }
        
        defaultAttributedString.addAttributes(defaultAttributes, range: NSMakeRange(0, defaultAttributedString.length))
        return (defaultAttributedString, removedKeys)
    }
    
    private func makeFontAdjustedAttributedString(for attributedString: NSAttributedString?,
                                                  fontTextStyle: UIFont.TextStyle) -> NSAttributedString? {
        guard let fontAdjustedAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else { return attributedString }
        
        fontAdjustedAttributedString.enumerateAttribute(NSAttributedString.Key.font,
                                                        in: NSMakeRange(0, fontAdjustedAttributedString.length),
                                                        options: [], using: { [weak self] (value, range, stop) in
            guard let oldFont = value as? UIFont else { return }
            
            var newFontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, tvOS 10.0, *) {
                newFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: fontTextStyle,
                                                                             compatibleWith: self?.traitCollection)
            } else {
                newFontDescriptor = UIFont.preferredFont(forTextStyle: fontTextStyle).fontDescriptor
            }
            
            let newFont = oldFont.withSize(newFontDescriptor.pointSize)
            fontAdjustedAttributedString.removeAttribute(.font, range: range)
            fontAdjustedAttributedString.addAttribute(.font, value: newFont, range: range)
        })
        
        return fontAdjustedAttributedString.copy() as? NSAttributedString
    }

}
