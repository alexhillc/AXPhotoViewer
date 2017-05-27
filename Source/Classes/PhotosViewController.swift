//
//  PhotosViewController.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

import UIKit
import ObjectiveC

@objc(BAPPhotosViewController) public class PhotosViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource,
                                                                  PhotoViewControllerDelegate, NetworkIntegrationDelegate {
    
    public weak var delegate: PhotosViewControllerDelegate?
    
    /// The photos to display in the PhotosViewController.
    public var photos: [Photo] {
        didSet {
            self.recycledViewControllers.removeLifeycleObserver(self)
            self.pageViewController.viewControllers?.removeLifeycleObserver(self)
            self.recycledLoadingViews.removeAll()
            self.recycledViewControllers.removeAll()
            self.setupPageViewController(initialIndex: 0)
        }
    }
    
    /// The number of photos to load surrounding the currently displayed photo.
    public var numberOfPhotosToPreload: Int = 2
    
    /// The underlying UIPageViewController that is used for swiping horizontally.
    /// - Important: `BAPPhotosViewController` is this page view controller's `UIPageViewControllerDelegate`, `UIPageViewControllerDataSource`.
    ///              Changing these values will result in breakage for the time being. (TODO)
    public let pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                         navigationOrientation: .horizontal,
                                                         options: [UIPageViewControllerOptionInterPageSpacingKey: 20])
    
    #if BAP_SDWI_SUPPORT
    fileprivate(set) var networkIntegration: NetworkIntegration = SDWebImageIntegration()
    #elseif BAP_AFN_SUPPORT
    fileprivate(set) var networkIntegration: NetworkIntegration = AFNetworkingIntegration()
    #else
    fileprivate(set) var networkIntegration: NetworkIntegration
    #endif
    
    fileprivate var recycledViewControllers = [PhotoViewController]()
    fileprivate var recycledLoadingViews = [String: [LoadingViewProtocol]]()
    
    fileprivate let notificationCenter = NotificationCenter()
    
    #if BAP_SDWI_SUPPORT || BAP_AFN_SUPPORT
    public init(photos: [Photo], initialIndex: Int = 0, delegate: PhotosViewControllerDelegate?) {
        self.delegate = delegate
        self.photos = photos
        assert(photos.count > initialIndex, "Invalid initial page index provided.")
    
        super.init(nibName: nil, bundle: nil)
        self.networkIntegration.delegate = self
    
        self.setupPageViewController(initialIndex: initialIndex)
    }
    #else
    public init(photos: [Photo], networkIntegration: NetworkIntegration, initialIndex: Int = 0, delegate: PhotosViewControllerDelegate?) {
        self.delegate = delegate
        self.networkIntegration = networkIntegration
        self.photos = photos
        assert(photos.count > initialIndex, "Invalid initial page index provided.")
        
        super.init(nibName: nil, bundle: nil)
        self.networkIntegration.delegate = self
        
        self.setupPageViewController(initialIndex: initialIndex)
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
    
    fileprivate func setupPageViewController(initialIndex: Int) {
        let photoViewController = self.makePhotoViewController(for: initialIndex)
        photoViewController.applyPhoto(photos[initialIndex])
        photoViewController.pageIndex = initialIndex
        self.pageViewController.setViewControllers([photoViewController], direction: .forward, animated: false, completion: nil)
        self.loadPhotos(at: initialIndex)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.pageViewController.view.frame = self.view.bounds
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
        func cancelLoadIfNecessary(for photo: Photo) {
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
    public func photoViewController(_ photoViewController: PhotoViewController, retryDownloadFor photo: Photo) {
        guard photo.loadingState != .loading && photo.loadingState != .loaded else {
            return
        }
        
        photo.error = nil
        photo.loadingState = .loading
        self.networkIntegration.loadPhoto(photo)
    }
    
    // MARK: - NetworkIntegrationDelegate
    public func networkIntegration(_ networkIntegration: NetworkIntegration, loadDidFinishWith photo: Photo) {
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
    
    public func networkIntegration(_ networkIntegration: NetworkIntegration, loadDidFailWith error: Error, for photo: Photo) {
        photo.loadingState = .loadingFailed
        photo.error = error
        self.notificationCenter.post(name: .photoImageUpdate,
                                     object: photo,
                                     userInfo: [
                                        PhotosViewControllerNotification.ErrorKey: error,
                                        PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loadingFailed
                                     ])
    }
    
    public func networkIntegration(_ networkIntegration: NetworkIntegration, didUpdateLoadingProgress progress: Progress, for photo: Photo) {
        photo.progress = progress
        self.notificationCenter.post(name: .photoLoadingProgressUpdate,
                                     object: photo,
                                     userInfo: [PhotosViewControllerNotification.ProgressKey: progress])
    }

}

// MARK: - UIViewController observer extensions
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

// MARK: - PhotosViewControllerDelegate
@objc(BAPPhotosViewControllerDelegate) public protocol PhotosViewControllerDelegate {
    
    /// Called just after the `PhotoViewController` is initialized/reused as an opportunity to configure the view controller
    /// before it comes onscreen.
    ///
    /// - Parameters:
    ///   - photosViewController: The `PhotosViewController` that will display the view controller.
    ///   - photoViewController: The related `PhotoViewController`.
    @objc optional func photosViewController(_ photosViewController: PhotosViewController,
                                             prepareViewControllerForDisplay photoViewController: PhotoViewController)
    
    /// Called just before the `PhotoViewController` is recycled as an opportunity to prepare the view controller for offscreen.
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
                                       loadingViewClassFor photo: Photo) -> LoadingViewProtocol.Type
    
}

// MARK: - Notification definitions
// Keep Obj-C land happy
@objc(BAPPhotosViewControllerNotification) public class PhotosViewControllerNotification: NSObject {
    static let ProgressUpdate = Notification.Name.photoLoadingProgressUpdate.rawValue
    static let ImageUpdate = Notification.Name.photoImageUpdate.rawValue
    static let ImageKey = "BAPhotosViewControllerImage"
    static let ImageDataKey = "BAPhotosViewControllerImageData"
    static let LoadingStateKey = "BAPhotosViewControllerLoadingState"
    static let ProgressKey = "BAPhotosViewControllerProgress"
    static let ErrorKey = "BAPhotosViewControllerError"
}

public extension Notification.Name {
    static let photoLoadingProgressUpdate = Notification.Name("BAPhotoLoadingProgressUpdateNotification")
    static let photoImageUpdate = Notification.Name("BAPhotoImageUpdateNotification")
}
