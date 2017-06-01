//
//  PhotosViewController.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

import UIKit
import ObjectiveC

@objc(AXPhotosViewController) public class PhotosViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource,
                                                                  PhotoViewControllerDelegate, UIScrollViewDelegate, NetworkIntegrationDelegate {
    
    public weak var delegate: PhotosViewControllerDelegate?
    
    /// The underlying `OverlayView` that is used for displaying photo captions, titles, and actions.
    public let overlayView = OverlayView()
    
    /// The photos to display in the PhotosViewController.
    public var photos: [PhotoProtocol] {
        didSet {
            self.recycledViewControllers.removeLifeycleObserver(self)
            self.pageViewController.viewControllers?.removeLifeycleObserver(self)
            self.recycledLoadingViews.removeAll()
            self.recycledViewControllers.removeAll()
            self.networkIntegration.cancelAllLoads()
            self.configurePageViewController(initialPhotoIndex: 0)
        }
    }
    
    /// The number of photos to load surrounding the currently displayed photo.
    public var numberOfPhotosToPreload: Int = 2
    
    /// Space between photos, measured in points.
    public let interPhotoSpacing: CGFloat = 20
    
    /// The underlying UIPageViewController that is used for swiping horizontally.
    /// - Important: `AXPhotosViewController` is this page view controller's `UIPageViewControllerDelegate`, `UIPageViewControllerDataSource`.
    ///              Changing these values will result in breakage.
    public let pageViewController: UIPageViewController
    
    #if AX_SDWI_SUPPORT
    public let networkIntegration: NetworkIntegration = SDWebImageIntegration()
    #elseif AX_AFN_SUPPORT
    public let networkIntegration: NetworkIntegration = AFNetworkingIntegration()
    #else
    public let networkIntegration: NetworkIntegration
    #endif
    
    // MARK: - Private variables
    fileprivate enum HorizontalSwipeDirection {
        case none, left, right
    }
    
    fileprivate var initialPhotoIndex: Int?
    fileprivate var currentPhotoIndex: Int = 0 {
        didSet {
            self.updateOverlay(for: currentPhotoIndex)
        }
    }
    
    fileprivate var isSizeTransitioning = false
    
    fileprivate var orderedViewControllers = [PhotoViewController]()
    fileprivate var recycledViewControllers = [PhotoViewController]()
    fileprivate var recycledLoadingViews = [String: [LoadingViewProtocol]]()
    
    fileprivate let notificationCenter = NotificationCenter()
    
    // MARK: - Initialization
    #if AX_SDWI_SUPPORT || AX_AFN_SUPPORT
    public init(photos: [PhotoProtocol], initialPhotoIndex: Int? = nil, delegate: PhotosViewControllerDelegate?) {
        self.pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                       navigationOrientation: .horizontal,
                                                       options: [UIPageViewControllerOptionInterPageSpacingKey: self.interPhotoSpacing])
        self.delegate = delegate
        self.photos = photos

        if let initialPhotoIndex = initialPhotoIndex {
            assert(photos.count > initialPhotoIndex, "Invalid initial photo index provided.")
            self.initialPhotoIndex = initialPhotoIndex
        }
    
        super.init(nibName: nil, bundle: nil)
        self.networkIntegration.delegate = self
    }
    #else
    public init(photos: [PhotoProtocol], initialPhotoIndex: Int? = nil, networkIntegration: NetworkIntegration, delegate: PhotosViewControllerDelegate?) {
        self.pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                       navigationOrientation: .horizontal,
                                                       options: [UIPageViewControllerOptionInterPageSpacingKey: self.interPhotoSpacing])
        self.delegate = delegate
        self.networkIntegration = networkIntegration
        self.photos = photos

        if let initialPhotoIndex = initialPhotoIndex {
            assert(photos.count > initialPhotoIndex, "Invalid initial photo index provided.")
            self.initialPhotoIndex = initialPhotoIndex
        }
    
        super.init(nibName: nil, bundle: nil)
        self.networkIntegration.delegate = self
    }
    #endif
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.recycledViewControllers.removeLifeycleObserver(self)
        self.pageViewController.viewControllers?.removeLifeycleObserver(self)
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.recycledViewControllers.removeLifeycleObserver(self)
        self.recycledLoadingViews.removeAll()
        self.recycledViewControllers.removeAll()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        self.pageViewController.addScrollDelegate(self)
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
        
        self.configurePageViewController(initialPhotoIndex: self.initialPhotoIndex ?? 0)
        self.initialPhotoIndex = nil
        
        self.overlayView.isUserInteractionEnabled = false
        self.view.addSubview(self.overlayView)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.isSizeTransitioning = true
        coordinator.animate(alongsideTransition: nil) { [weak self] (context) in
            self?.isSizeTransitioning = false
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.pageViewController.view.frame = self.view.bounds
        self.overlayView.frame = self.view.bounds
    }
    
    // MARK: - Page VC Configuration
    fileprivate func configurePageViewController(initialPhotoIndex: Int) {
        let photoViewController = self.makePhotoViewController(for: initialPhotoIndex)
        photoViewController.applyPhoto(photos[initialPhotoIndex])
        photoViewController.pageIndex = initialPhotoIndex
        self.pageViewController.setViewControllers([photoViewController], direction: .forward, animated: false, completion: nil)
        self.currentPhotoIndex = initialPhotoIndex
        self.loadPhotos(at: initialPhotoIndex)
    }
    
    // MARK: - Overlay
    fileprivate func updateOverlay(for photoIndex: Int) {
        let photo = self.photos[photoIndex]
        self.overlayView.title = NSLocalizedString("\(photoIndex + 1) of \(self.photos.count)", comment: "")
        self.overlayView.captionView.applyCaptionInfo(attributedTitle: photo.attributedTitle,
                                                      attributedDescription: photo.attributedDescription,
                                                      attributedCredit: photo.attributedCredit)
        self.overlayView.setNeedsLayout()
        self.overlayView.layoutIfNeeded()
    }
    
    // MARK: - Loading helpers
    fileprivate func loadPhotos(at index: Int) {
        let startIndex = (((index - (self.numberOfPhotosToPreload / 2)) >= 0) ? (index - (self.numberOfPhotosToPreload / 2)) : 0)
        let indexes = startIndex..<(startIndex + self.numberOfPhotosToPreload + 1)
        
        for index in indexes {
            guard self.photos.count > index else {
                return
            }
            
            let photo = self.photos[index]
            if photo.loadingState == .notLoaded {
                photo.loadingState = .loading
                self.networkIntegration.loadPhoto(photo)
            }
        }
    }
    
    fileprivate func cancelLoadForPhotos(at index: Int) {
        let lowerIndex = (index - (self.numberOfPhotosToPreload / 2) - 1 >= 0) ? index - (self.numberOfPhotosToPreload / 2) - 1: NSNotFound
        let upperIndex = (index + (self.numberOfPhotosToPreload / 2) + 1 < self.photos.count) ? index + (self.numberOfPhotosToPreload / 2) + 1 : NSNotFound
        
        weak var weakSelf = self
        func cancelLoadIfNecessary(for photo: PhotoProtocol) {
            guard let uSelf = weakSelf, photo.loadingState == .loading else {
                return
            }
            
            uSelf.networkIntegration.cancelLoad(for: photo)
            photo.loadingState = .notLoaded
        }
        
        if lowerIndex != NSNotFound {
            cancelLoadIfNecessary(for: self.photos[lowerIndex])
        }
        
        if upperIndex != NSNotFound {
            cancelLoadIfNecessary(for: self.photos[upperIndex])
        }
    }
    
    // MARK: - Lifecycle KVO
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &PhotoViewControllerLifecycleContext {
            guard let photoViewController = object as? PhotoViewController else {
                return
            }
            
            if change?[.newKey] is NSNull {
                self.delegate?.photosViewController?(self, prepareViewControllerForEndDisplay: photoViewController)
                self.recyclePhotoViewController(photoViewController)
            } else {
                self.delegate?.photosViewController?(self, prepareViewControllerForDisplay: photoViewController)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Reuse / Factory
    fileprivate func makePhotoViewController(for pageIndex: Int) -> PhotoViewController {
        let photo = self.photos[pageIndex]
        var photoViewController: PhotoViewController
        
        if self.recycledViewControllers.count > 0 {
            photoViewController = self.recycledViewControllers.removeLast()
            photoViewController.loadingView = self.makeLoadingView(for: pageIndex)
            photoViewController.prepareForReuse()
        } else {
            photoViewController = PhotoViewController(loadingView: self.makeLoadingView(for: pageIndex), notificationCenter: self.notificationCenter)
            photoViewController.addLifecycleObserver(self)
            photoViewController.delegate = self
        }
        
        photoViewController.pageIndex = pageIndex
        photoViewController.applyPhoto(photo)
        
        let insertionIndex = self.orderedViewControllers.insertionIndex(of: photoViewController, isOrderedBefore: { $0.pageIndex < $1.pageIndex })
        if !insertionIndex.alreadyExists {
            self.orderedViewControllers.insert(photoViewController, at: insertionIndex.index)
        }
        
        return photoViewController
    }
    
    fileprivate func makeLoadingView(for pageIndex: Int) -> LoadingViewProtocol {
        let photo = self.photos[pageIndex]
        var loadingView: LoadingViewProtocol
        var loadingViewClass: LoadingViewProtocol.Type

        if let uLoadingViewClass = photo.loadingViewClass {
            loadingViewClass = uLoadingViewClass
        } else if let uLoadingViewClass = self.delegate?.photosViewController?(self, loadingViewClassFor: photo) {
            assert(uLoadingViewClass is UIView.Type, "`loadingView` must be a `UIView`")
            loadingViewClass = uLoadingViewClass
        } else {
            loadingViewClass = LoadingView.self
        }
        
        photo.loadingViewClass = loadingViewClass
        
        let key = String(describing: loadingViewClass)
        if var recycledLoadingViews = self.recycledLoadingViews[key], recycledLoadingViews.count > 0 {
            loadingView = recycledLoadingViews.removeLast()
            self.recycledLoadingViews[key] = recycledLoadingViews
        } else {
            loadingView = (loadingViewClass as! UIView.Type).init() as! LoadingViewProtocol
        }
        
        return loadingView
    }
    
    // MARK: - Recycling
    fileprivate func recyclePhotoViewController(_ photoViewController: PhotoViewController) {
        guard !self.recycledViewControllers.contains(photoViewController) else {
            return
        }
        
        let insertionIndex = self.orderedViewControllers.insertionIndex(of: photoViewController, isOrderedBefore: { $0.pageIndex < $1.pageIndex })
        if insertionIndex.alreadyExists {
            self.orderedViewControllers.remove(at: insertionIndex.index)
        }
        
        if let loadingView = photoViewController.loadingView as? UIView {
            photoViewController.loadingView = nil
            
            let key = String(describing: type(of: loadingView))
            if self.recycledLoadingViews[key] == nil {
                self.recycledLoadingViews[key] = [LoadingViewProtocol]()
            }
            self.recycledLoadingViews[key]?.append(loadingView as! LoadingViewProtocol)
        }
        
        self.recycledViewControllers.append(photoViewController)
    }
    
    // MARK: - UIPageViewControllerDataSource
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first as? PhotoViewController else {
            return
        }
        
        self.loadPhotos(at: viewController.pageIndex)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = pageViewController.viewControllers?.first as? PhotoViewController else {
            return
        }
        
        self.cancelLoadForPhotos(at: viewController.pageIndex)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let uViewController = viewController as? PhotoViewController else {
            assertionFailure("Paging VC must be a subclass of `PhotoViewController`.")
            return nil
        }
        
        return self.pageViewController(pageViewController, viewControllerAt: uViewController.pageIndex - 1)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let uViewController = viewController as? PhotoViewController else {
            assertionFailure("Paging VC must be a subclass of `PhotoViewController`.")
            return nil
        }
        
        return self.pageViewController(pageViewController, viewControllerAt: uViewController.pageIndex + 1)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAt index: Int) -> UIViewController? {
        guard index >= 0 && self.photos.count > index else {
            return nil
        }
        
        return self.makePhotoViewController(for: index)
    }
    
    // MARK: - PhotoViewControllerDelegate
    public func photoViewController(_ photoViewController: PhotoViewController, retryDownloadFor photo: PhotoProtocol) {
        guard photo.loadingState != .loading && photo.loadingState != .loaded else {
            return
        }
        
        photo.error = nil
        photo.loadingState = .loading
        self.networkIntegration.loadPhoto(photo)
    }
    
    
    // MARK: - UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !self.isSizeTransitioning else {
            return
        }
        
        let percent = (scrollView.contentOffset.x - scrollView.frame.size.width) / scrollView.frame.size.width
        
        var horizontalSwipeDirection: HorizontalSwipeDirection = .none
        if percent > CGFloat.ulpOfOne {
            horizontalSwipeDirection = .right
        } else if percent < -CGFloat.ulpOfOne {
            horizontalSwipeDirection = .left
        }

        let swipePercent = (horizontalSwipeDirection == .left) ? (1 - abs(percent)) : abs(percent)
        var lowIndex: Int = NSNotFound
        var highIndex: Int = NSNotFound
        
        let viewControllers = self.computeVisibleViewControllers(in: scrollView)
        if horizontalSwipeDirection == .left {
            guard let viewController = viewControllers.first else {
                return
            }
            
            if viewControllers.count > 1 {
                lowIndex = viewController.pageIndex
                if lowIndex < self.photos.count {
                    highIndex = lowIndex + 1
                }
            } else {
                highIndex = viewController.pageIndex
            }
        } else if horizontalSwipeDirection == .right {
            guard let viewController = viewControllers.last else {
                return
            }
            
            if viewControllers.count > 1 {
                highIndex = viewController.pageIndex
                if highIndex > 0 {
                    lowIndex = highIndex - 1
                }
            } else {
                lowIndex = viewController.pageIndex
            }
        }
        
        guard lowIndex != NSNotFound && highIndex != NSNotFound else {
            return
        }
        
        if swipePercent < 0.5 && self.currentPhotoIndex != lowIndex  {
            self.currentPhotoIndex = lowIndex
        } else if swipePercent > 0.5 && self.currentPhotoIndex != highIndex {
            self.currentPhotoIndex = highIndex
        }
    }
    
    fileprivate func computeVisibleViewControllers(in referenceView: UIScrollView) -> [PhotoViewController] {
        var visibleViewControllers = [PhotoViewController]()
        
        for viewController in self.orderedViewControllers {
            let origin = CGPoint(x: viewController.view.frame.origin.x - (self.interPhotoSpacing / 2),
                                 y: viewController.view.frame.origin.y)
            let size = CGSize(width: viewController.view.frame.size.width + self.interPhotoSpacing,
                              height: viewController.view.frame.size.height)
            let conversionRect = CGRect(origin: origin, size: size)
            
            if referenceView.convert(conversionRect, from: viewController.view).intersects(referenceView.bounds) {
                visibleViewControllers.append(viewController)
            }
        }
        
        return visibleViewControllers
    }
    
    // MARK: - NetworkIntegrationDelegate
    public func networkIntegration(_ networkIntegration: NetworkIntegration, loadDidFinishWith photo: PhotoProtocol) {
        if let imageData = photo.imageData {
            photo.loadingState = .loaded
            self.notificationCenter.post(name: .photoImageUpdate,
                                         object: photo,
                                         userInfo: [
                                            PhotosViewControllerNotification.ImageDataKey: imageData,
                                            PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loaded
                                         ])
        } else if let image = photo.image {
            photo.loadingState = .loaded
            self.notificationCenter.post(name: .photoImageUpdate,
                                         object: photo,
                                         userInfo: [
                                            PhotosViewControllerNotification.ImageKey: image,
                                            PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loaded
                                         ])
        }
    }
    
    public func networkIntegration(_ networkIntegration: NetworkIntegration, loadDidFailWith error: Error, for photo: PhotoProtocol) {
        photo.loadingState = .loadingFailed
        photo.error = error
        self.notificationCenter.post(name: .photoImageUpdate,
                                     object: photo,
                                     userInfo: [
                                        PhotosViewControllerNotification.ErrorKey: error,
                                        PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loadingFailed
                                     ])
    }
    
    public func networkIntegration(_ networkIntegration: NetworkIntegration, didUpdateLoadingProgress progress: Progress, for photo: PhotoProtocol) {
        photo.progress = progress
        self.notificationCenter.post(name: .photoLoadingProgressUpdate,
                                     object: photo,
                                     userInfo: [PhotosViewControllerNotification.ProgressKey: progress])
    }

}

// MARK: - Observer extensions
fileprivate var PhotoViewControllerLifecycleContext: UInt8 = 0
fileprivate extension Array where Element: UIViewController {
    
    func removeLifeycleObserver(_ observer: NSObject) -> Void {
        self.forEach({ ($0 as UIViewController).removeLifecycleObserver(observer) })
    }
    
}

fileprivate extension UIViewController {
    
    func addLifecycleObserver(_ observer: NSObject) -> Void {
        self.addObserver(observer, forKeyPath: #keyPath(parent), options: .new, context: &PhotoViewControllerLifecycleContext)
    }
    
    func removeLifecycleObserver(_ observer: NSObject) -> Void {
        self.removeObserver(observer, forKeyPath: #keyPath(parent), context: &PhotoViewControllerLifecycleContext)
    }
    
}

fileprivate extension UIPageViewController {
    
    func addScrollDelegate(_ delegate: UIScrollViewDelegate) {
        guard let scrollView = self.view.subviews.filter({ $0 is UIScrollView }).first as? UIScrollView else {
            assertionFailure("Unable to locate the underlying `UIScrollView`. This will most definitely cause unexpected behavior.")
            return
        }
        
        scrollView.delegate = delegate
    }
    
}

// MARK: - PhotosViewControllerDelegate
@objc(AXPhotosViewControllerDelegate) public protocol PhotosViewControllerDelegate {
    
    /// Called just after the `PhotoViewController` is added to the view hierarchy as an opportunity to configure the view controller
    /// before it comes onscreen.
    ///
    /// - Parameters:
    ///   - photosViewController: The `PhotosViewController` that will display the view controller.
    ///   - photoViewController: The related `PhotoViewController`.
    @objc optional func photosViewController(_ photosViewController: PhotosViewController,
                                             prepareViewControllerForDisplay photoViewController: PhotoViewController)
    
    /// Called just before the `PhotoViewController` is removed from the view hierarchy as an opportunity to prepare the 
    /// view controller for offscreen.
    ///
    /// - Parameters:
    ///   - photosViewController: The `PhotosViewController` ending display of the view controller.
    ///   - photoViewController: The related `PhotoViewController`.
    @objc optional func photosViewController(_ photosViewController: PhotosViewController,
                                             prepareViewControllerForEndDisplay photoViewController: PhotoViewController)
    
    /// Called just before a new `PhotoViewController` is initialized. This custom `loadingView` must conform to `LoadingViewProtocol`.
    ///
    /// - Parameters:
    ///   - photosViewController: The `PhotosViewController` requesting the loading view.
    ///   - photo: The related `Photo`.
    /// - Returns: A `UIView` that conforms to `LoadingViewProtocol`.
    @objc(photosViewController:loadingViewClassForPhoto:)
    optional func photosViewController(_ photosViewController: PhotosViewController,
                                       loadingViewClassFor photo: PhotoProtocol) -> LoadingViewProtocol.Type
    
}

// MARK: - Notification definitions
// Keep Obj-C land happy
@objc(AXPhotosViewControllerNotification) public class PhotosViewControllerNotification: NSObject {
    static let ProgressUpdate = Notification.Name.photoLoadingProgressUpdate.rawValue
    static let ImageUpdate = Notification.Name.photoImageUpdate.rawValue
    static let ImageKey = "AXhotosViewControllerImage"
    static let ImageDataKey = "AXhotosViewControllerImageData"
    static let LoadingStateKey = "AXhotosViewControllerLoadingState"
    static let ProgressKey = "AXhotosViewControllerProgress"
    static let ErrorKey = "AXhotosViewControllerError"
}

public extension Notification.Name {
    static let photoLoadingProgressUpdate = Notification.Name("AXhotoLoadingProgressUpdateNotification")
    static let photoImageUpdate = Notification.Name("AXhotoImageUpdateNotification")
}
