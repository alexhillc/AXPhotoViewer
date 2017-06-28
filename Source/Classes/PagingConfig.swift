//
//  PagingConfiguration.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

@objc(AXPagingConfig) open class PagingConfig: NSObject {
    
    /// Navigation configuration to be applied to the internal pager of the `PhotosViewController`.
    fileprivate(set) var navigationOrientation: UIPageViewControllerNavigationOrientation
    
    /// Space between photos, measured in points. Applied to the internal pager of the `PhotosViewController` at initialization.
    fileprivate(set) var interPhotoSpacing: CGFloat

    public init(navigationOrientation: UIPageViewControllerNavigationOrientation, interPhotoSpacing: CGFloat) {
        self.navigationOrientation = navigationOrientation
        self.interPhotoSpacing = interPhotoSpacing
        super.init()
    }
    
    public convenience override init() {
        self.init(navigationOrientation: .horizontal, interPhotoSpacing: 20)
    }
    
}
