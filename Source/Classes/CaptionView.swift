//
//  CaptionView.swift
//  Pods
//
//  Created by Alex Hill on 5/28/17.
//
//

import UIKit

@objc(BAPCaptionView) public class CaptionView: UIView, CaptionViewProtocol {
    
    var titleLabel = UILabel()
    var descriptionLabel = UILabel()
    var creditLabel = UILabel()
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        
        self.titleLabel.textColor = .white
        self.addSubview(self.titleLabel)
        
        self.descriptionLabel.textColor = .white
        self.addSubview(self.descriptionLabel)
        
        self.creditLabel.textColor = .white
        self.addSubview(self.creditLabel)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func applyCaptionInfo(attributedTitle: NSAttributedString?,
                          attributedDescription: NSAttributedString?,
                          attributedCredit: NSAttributedString?) {
        
        self.titleLabel.isHidden = attributedTitle?.string.isEmpty ?? true
        self.titleLabel.attributedText = attributedTitle
        
        self.descriptionLabel.isHidden = attributedDescription?.string.isEmpty ?? true
        self.descriptionLabel.attributedText = attributedDescription
        
        self.creditLabel.isHidden = attributedCredit?.string.isEmpty ?? true
        self.creditLabel.attributedText = attributedCredit
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.computeSize(for: self.frame.size, applyLayout: true)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applyLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applyLayout: Bool) -> CGSize {
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: self.traitCollection)
        self.descriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: self.traitCollection)
        self.creditLabel.font = UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: self.traitCollection)
        
        let VerticalPadding: CGFloat = 10
        
        let titleLabelSize = self.titleLabel.sizeThatFits(constrainedSize)
        let descriptionLabelSize = self.descriptionLabel.sizeThatFits(constrainedSize)
        let creditLabelSize = self.creditLabel.sizeThatFits(constrainedSize)
        
        var yOffset: CGFloat = 0
        
        if !self.titleLabel.isHidden {
            let titleLabelFrame = CGRect(origin: CGPoint(x: (constrainedSize.width - titleLabelSize.width) / 2,
                                                         y: VerticalPadding),
                                         size: titleLabelSize)
            yOffset += titleLabelFrame.origin.y + titleLabelFrame.size.height
            
            if self.descriptionLabel.isHidden && self.creditLabel.isHidden {
                yOffset += VerticalPadding
            }
            
            if applyLayout {
                self.titleLabel.frame = titleLabelFrame
            }
        }
        
        if !self.descriptionLabel.isHidden {
            if self.titleLabel.isHidden {
                yOffset += VerticalPadding
            } else {
                yOffset += 2
            }
            
            let descriptionLabelFrame = CGRect(origin: CGPoint(x: (constrainedSize.width - descriptionLabelSize.width) / 2,
                                                               y: yOffset),
                                               size: descriptionLabelSize)
            yOffset += descriptionLabelFrame.size.height
            
            if self.creditLabel.isHidden {
                yOffset += VerticalPadding
            }
            
            if applyLayout {
                self.descriptionLabel.frame = descriptionLabelFrame
            }
        }
        
        if !self.creditLabel.isHidden {
            if self.titleLabel.isHidden && self.descriptionLabel.isHidden {
                yOffset += VerticalPadding
            } else {
                yOffset += 2
            }
            
            let creditLabelFrame = CGRect(origin: CGPoint(x: (constrainedSize.width - creditLabelSize.width) / 2,
                                                          y: yOffset),
                                          size: creditLabelSize)
            yOffset += creditLabelFrame.size.height + VerticalPadding
            
            if applyLayout {
                self.creditLabel.frame = creditLabelFrame
            }
        }
        
        return CGSize(width: constrainedSize.width, height: yOffset)
    }

}
