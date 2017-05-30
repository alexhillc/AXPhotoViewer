//
//  OverlayView.swift
//  Pods
//
//  Created by Alex Hill on 5/28/17.
//
//

import UIKit

let OverlayTransitionAnimationDuration: TimeInterval = 0.25

@objc(BAPOverlayView) public class OverlayView: UIView {
    
    /// The caption view to be used in the overlay.
    public var captionView: CaptionViewProtocol = CaptionView() {
        didSet {
            (oldValue as? UIView)?.removeFromSuperview()
            self.setNeedsLayout()
        }
    }
    
    /// The navigation bar used to set the `titleView`, `leftBarButtonItems`, `rightBarButtonItems`
    public let navigationBar = UINavigationBar()
    
    /// The title view displayed in the navigation bar. This view is sized and centered between the `leftBarButtonItems` and `rightBarButtonItems`.
    /// This is prioritized over `title`.
    var titleView: UIView? {
        set(value) {
            self.navigationItem.titleView = value
        }
        get {
            return self.navigationItem.titleView
        }
    }
    
    /// The title displayed in the navigation bar. This string is centered between the `leftBarButtonItems` and `rightBarButtonItems`.
    var title: String? {
        set(value) {
            self.navigationItem.title = value
        }
        get {
            return self.navigationItem.title
        }
    }
    
    /// The title text attributes inherited by the `title`.
    var titleTextAttributes: [String: Any]? {
        set(value) {
            self.navigationBar.titleTextAttributes = value
        }
        get {
            return self.navigationBar.titleTextAttributes
        }
    }
    
    /// The bar button item that appears in the top left corner of the overlay.
    var leftBarButtonItem: UIBarButtonItem? {
        set(value) {
            self.navigationItem.setLeftBarButton(value, animated: false)
        }
        get {
            return self.navigationItem.leftBarButtonItem
        }
    }
    
    /// The bar button items that appear in the top left corner of the overlay.
    var leftBarButtonItems: [UIBarButtonItem]? {
        set(value) {
            self.navigationItem.setLeftBarButtonItems(value, animated: false)
        }
        get {
            return self.navigationItem.leftBarButtonItems
        }
    }

    /// The bar button item that appears in the top right corner of the overlay.
    var rightBarButtonItem: UIBarButtonItem? {
        set(value) {
            self.navigationItem.setRightBarButton(value, animated: false)
        }
        get {
            return self.navigationItem.rightBarButtonItem
        }
    }
    
    /// The bar button items that appear in the top right corner of the overlay.
    var rightBarButtonItems: [UIBarButtonItem]? {
        set(value) {
            self.navigationItem.setRightBarButtonItems(value, animated: false)
        }
        get {
            return self.navigationItem.rightBarButtonItems
        }
    }
    
    /// The underlying `UINavigationItem` used for setting the `titleView`, `leftBarButtonItems`, `rightBarButtonItems`.
    fileprivate var navigationItem = UINavigationItem()
    
    init() {
        super.init(frame: .zero)
        
        self.navigationBar.backgroundColor = .clear
        self.navigationBar.barTintColor = nil
        self.navigationBar.isTranslucent = true
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationBar.items = [self.navigationItem]
        
        self.addSubview(self.navigationBar)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let navigationBarSize: CGSize = self.navigationBar.sizeThatFits(self.frame.size)
        self.navigationBar.frame = CGRect(origin: .zero, size: navigationBarSize)
        
        if let captionView = self.captionView as? UIView {
            if captionView.superview == nil {
                self.addSubview(captionView)
            }
            
            let captionViewSize = captionView.sizeThatFits(self.frame.size)
            UIView.animate(withDuration: OverlayTransitionAnimationDuration, animations: { [weak self] in
                guard let uSelf = self else {
                    return
                }
                
                captionView.frame = CGRect(origin: CGPoint(x: 0, y: uSelf.frame.size.height - captionViewSize.height),
                                           size: captionViewSize)
            })
            captionView.setNeedsLayout()
        }
    }
}
