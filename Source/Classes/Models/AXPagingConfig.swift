//
//  AXPagingConfig.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/1/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

fileprivate let DefaultHorizontalSpacing: CGFloat = 20

@objc open class AXPagingConfig: NSObject {
    
    /// Navigation configuration to be applied to the internal pager of the `PhotosViewController`.
    @objc fileprivate(set) var navigationOrientation: UIPageViewControllerNavigationOrientation
    
    /// Space between photos, measured in points. Applied to the internal pager of the `PhotosViewController` at initialization.
    @objc fileprivate(set) var interPhotoSpacing: CGFloat
    
    /// The loading view class which will be instantiated instead of the default `AXLoadingView`.
    @objc fileprivate(set) var loadingViewClass: AXLoadingViewProtocol.Type = AXLoadingView.self
    
    @objc public init(navigationOrientation: UIPageViewControllerNavigationOrientation,
                      interPhotoSpacing: CGFloat,
                      loadingViewClass: AXLoadingViewProtocol.Type? = nil) {
        
        self.navigationOrientation = navigationOrientation
        self.interPhotoSpacing = interPhotoSpacing
        
        super.init()
        
        if let loadingViewClass = loadingViewClass {
            guard loadingViewClass is UIView.Type else {
                assertionFailure("`loadingViewClass` must be a UIView.")
                return
            }
            
            self.loadingViewClass = loadingViewClass
        }
    }
    
    @objc public convenience override init() {
        self.init(navigationOrientation: .horizontal, interPhotoSpacing: DefaultHorizontalSpacing, loadingViewClass: nil)
    }
    
    @objc public convenience init(navigationOrientation: UIPageViewControllerNavigationOrientation) {
        self.init(navigationOrientation: navigationOrientation, interPhotoSpacing: DefaultHorizontalSpacing, loadingViewClass: nil)
    }
    
    @objc public convenience init(interPhotoSpacing: CGFloat) {
        self.init(navigationOrientation: .horizontal, interPhotoSpacing: interPhotoSpacing, loadingViewClass: nil)
    }
    
    @objc public convenience init(loadingViewClass: AXLoadingViewProtocol.Type?) {
        self.init(navigationOrientation: .horizontal, interPhotoSpacing: DefaultHorizontalSpacing, loadingViewClass: loadingViewClass)
    }
    
}
