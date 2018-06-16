//
//  AXStackableViewContainer.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 9/17/17.
//

import UIKit

@objc public class AXStackableViewContainer: UIView {
    
    weak var delegate: AXStackableViewContainerDelegate?
    
    /// The inset of the contents of the `StackableViewContainer`.
    /// For internal use only.
    var contentInset: UIEdgeInsets = .zero
    
    @objc fileprivate(set) var anchorPoint: AXStackableViewContainerAnchorPoint
    @objc enum AXStackableViewContainerAnchorPoint: Int {
        case top, bottom
    }

    @objc(initWithViews:anchoredAtPoint:)
    init(views: [UIView], anchoredAt point: AXStackableViewContainerAnchorPoint) {
        self.anchorPoint = point
        super.init(frame: .zero)
        
        for view in views {
            self.addSubview(view)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.computeSize(for: self.frame.size, applySizingLayout: true)
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applySizingLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applySizingLayout: Bool) -> CGSize {
        var yOffset: CGFloat = 0
        let xOffset: CGFloat = self.contentInset.left
        var constrainedInsetSize = constrainedSize
        constrainedInsetSize.width -= (self.contentInset.left + self.contentInset.right)
        
        let subviews = (self.anchorPoint == .top) ? self.subviews : self.subviews.reversed()
        for subview in subviews {
            let size = subview.sizeThatFits(constrainedInsetSize)
            var frame: CGRect
            
            if yOffset == 0 && size.height > 0 {
                yOffset = self.contentInset.top
            }
            
            // special cases
            #if os(iOS)
            if subview is UIToolbar || subview is UINavigationBar {
                frame = CGRect(x: xOffset, y: yOffset, width: constrainedInsetSize.width, height: size.height)
            } else {
                frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: size)
            }
            #else
            if subview is UINavigationBar {
                frame = CGRect(x: xOffset, y: yOffset, width: constrainedInsetSize.width, height: size.height)
            } else {
                frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: size)
            }
            #endif
            
            yOffset += frame.size.height
            
            if applySizingLayout {
                subview.frame = frame
                subview.setNeedsLayout()
                subview.layoutIfNeeded()
            }
        }
        
        if (yOffset - self.contentInset.top) > 0 {
            yOffset += self.contentInset.bottom
        }
        
        return CGSize(width: constrainedSize.width, height: yOffset)
    }
    
    // MARK: - AXStackableViewContainerDelegate
    override public func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        self.delegate?.stackableViewContainer?(self, didAddSubview: subview)
    }
    
    override public func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        self.delegate?.stackableViewContainer?(self, willRemoveSubview: subview)
    }
    
}

@objc protocol AXStackableViewContainerDelegate: class {
    
    @objc optional func stackableViewContainer(_ stackableViewContainer: AXStackableViewContainer, didAddSubview: UIView)
    @objc optional func stackableViewContainer(_ stackableViewContainer: AXStackableViewContainer, willRemoveSubview: UIView)
    
}
