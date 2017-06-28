//
//  PagingConfiguration.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

fileprivate let DefaultHorizontalSpacing: CGFloat = 20

@objc(AXPagingConfig) open class PagingConfig: NSObject {
    
    /// Navigation configuration to be applied to the internal pager of the `PhotosViewController`.
    fileprivate(set) var navigationOrientation: UIPageViewControllerNavigationOrientation
    
    /// Space between photos, measured in points. Applied to the internal pager of the `PhotosViewController` at initialization.
    fileprivate(set) var interPhotoSpacing: CGFloat
    
    /// The loading view class which will be instantiated instead of the default `AXLoadingView`.
    fileprivate(set) var loadingViewClass: LoadingViewProtocol.Type = LoadingView.self

    public init(navigationOrientation: UIPageViewControllerNavigationOrientation, interPhotoSpacing: CGFloat) {
        self.navigationOrientation = navigationOrientation
        self.interPhotoSpacing = interPhotoSpacing
        super.init()
    }
    
    public init(navigationOrientation: UIPageViewControllerNavigationOrientation,
                interPhotoSpacing: CGFloat, 
                loadingViewClass: LoadingViewProtocol.Type?) {
        
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
    
    public convenience override init() {
        self.init(navigationOrientation: .horizontal, interPhotoSpacing: DefaultHorizontalSpacing)
    }
    
    public convenience init(loadingViewClass: LoadingViewProtocol.Type?) {
        self.init()
        
        if let loadingViewClass = loadingViewClass {
            guard loadingViewClass is UIView.Type else {
                assertionFailure("`loadingViewClass` must be a UIView.")
                return
            }
            
            self.loadingViewClass = loadingViewClass
        }
    }
    
}
