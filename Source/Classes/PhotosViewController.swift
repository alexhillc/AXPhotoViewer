//
//  PhotosViewController.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

import UIKit
import ObjectiveC

private enum PhotoLoadingState: Int {
    case notLoaded, loading, loaded, loadingFailed
}

@objc(BAPPhotosViewController) class PhotosViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource,
                                                           NetworkIntegrationDelegate {
    
    // MARK: - Public
    
    weak var delegate: PhotosViewControllerDelegate?
    
    /// The photos to display in the PhotosViewController.
    var photos: [Photo] {
        didSet {
            self.recycledLoadingViews.removeAll()
            self.recycledViewControllers.removeAll()
            self.setupPageViewController(initialIndex: 0)
        }
    }
    
    /// The number of photos to load surrounding the currently displayed photo.
    var numberOfPhotosToPreload: Int = 2
    
    /// The underlying UIPageViewController that is used for swiping horizontally.
    /// - Important: `BAPPhotosViewController` is this page view controller's `UIPageViewControllerDelegate`, `UIPageViewControllerDataSource`.
    ///              Changing these values will result in breakage for the time being. (TODO)
    let pageViewController = UIPageViewController()
    
    #if BAP_SDWI_SUPPORT
    fileprivate var networkIntegration: NetworkIntegration = SDWebImageIntegration()
    #elseif BAP_AFN_SUPPORT
    fileprivate var networkIntegration: NetworkIntegration = AFNetworkingIntegration()
    #else
    fileprivate var networkIntegration: NetworkIntegration
    #endif
    
    fileprivate var recycledViewControllers = [PhotoViewController]()
    fileprivate var recycledLoadingViews = [String: [LoadingViewProtocol]]()
    
    fileprivate let notificationCenter = NotificationCenter()
    
    #if BAP_SDWI_SUPPORT || BAP_AFN_SUPPORT
    init(photos: [Photo], initialIndex: Int = 0, delegate: PhotosViewControllerDelegate?) {
        self.delegate = delegate
        self.photos = photos
        assert(photos.count > initialIndex, "Invalid initial page index provided.")
    
        super.init(nibName: nil, bundle: nil)
        self.networkIntegration.delegate = self
    
        self.setupPageViewController(initialIndex: initialIndex)
    }
    #else
    init(photos: [Photo], initialIndex: Int = 0, networkIntegration: NetworkIntegration, delegate: PhotosViewControllerDelegate?) {
        self.delegate = delegate
        self.networkIntegration = networkIntegration
        self.photos = photos
        assert(photos.count > initialIndex, "Invalid initial page index provided.")
        
        super.init(nibName: nil, bundle: nil)
        self.networkIntegration.delegate = self
        
        self.setupPageViewController(initialIndex: initialIndex)
    }
    #endif
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupPageViewController(initialIndex: Int) {
        let photoViewController = self.makePhotoViewController(for: initialIndex)
        photoViewController.applyPhoto(photos[initialIndex])
        photoViewController.pageIndex = initialIndex
        self.pageViewController.setViewControllers([photoViewController], direction: .forward, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.pageViewController.view.frame = self.view.bounds
    }
    
    fileprivate func loadPhotos(at index: Int) {
        let startIndex = (((index - (self.numberOfPhotosToPreload / 2)) >= 0) ? (index - (self.numberOfPhotosToPreload / 2)) : 0)
        let indexes = startIndex..<(startIndex + self.numberOfPhotosToPreload + 1)
        
        for index in indexes {
            guard self.photos.count > index else {
                return
            }
            
            let photo = self.photos[index]
            if photo.loadingState != .loading && photo.loadingState != .loaded {
                photo.loadingState = .loading
                self.networkIntegration.loadPhoto(photo)
            }
        }
    }
    
    // MARK: - Factory methods
    fileprivate func makePhotoViewController(for pageIndex: Int) -> PhotoViewController {
        let photo = self.photos[pageIndex]
        var photoViewController: PhotoViewController
        
        if self.recycledViewControllers.count > 0 {
            photoViewController = self.recycledViewControllers.removeLast()
            photoViewController.loadingView = self.makeLoadingView(for: pageIndex)
        } else {
            photoViewController = PhotoViewController(loadingView: self.makeLoadingView(for: pageIndex), notificationCenter: self.notificationCenter)
        }
        
        photoViewController.pageIndex = pageIndex
        photoViewController.applyPhoto(photo)
        
        return photoViewController
    }
    
    func makeLoadingView(for pageIndex: Int) -> LoadingViewProtocol {
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
    
    // MARK: - UIPageViewControllerDelegate
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard finished, let photoViewControllers = previousViewControllers as? [PhotoViewController] else {
            return
        }
        
        self.recycledViewControllers.append(contentsOf: photoViewControllers)
        for photoViewController in photoViewControllers {
            if let loadingView = photoViewController.loadingView as? UIView {
                loadingView.removeFromSuperview()
                photoViewController.loadingView = nil
                self.recycledLoadingViews[String(describing: type(of: loadingView))]?.append(loadingView as! LoadingViewProtocol)
            }
            
            self.recycledViewControllers.append(photoViewController)
        }
    }
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let photoViewController = viewController as? PhotoViewController else {
            assertionFailure("Paging VC must be a subclass of `PhotoViewController`.")
            return nil
        }
        
        let pageIndex = photoViewController.pageIndex - 1
        guard pageIndex >= 0 && self.photos.count > pageIndex else {
            return nil
        }
        
        self.loadPhotos(at: pageIndex)
        
        return self.makePhotoViewController(for: pageIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let photoViewController = viewController as? PhotoViewController else {
            assertionFailure("Paging VC must be a subclass of `PhotoViewController`.")
            return nil
        }
        
        let pageIndex = photoViewController.pageIndex + 1
        guard self.photos.count > pageIndex else {
            return nil
        }
        
        self.loadPhotos(at: pageIndex)
        
        return self.makePhotoViewController(for: pageIndex)
    }
    
    // MARK: - NetworkIntegrationDelegate
    func networkIntegration(_ networkIntegration: NetworkIntegration, loadDidFinishWith photo: Photo) {
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
    
    func networkIntegration(_ networkIntegration: NetworkIntegration, loadDidFailWith error: NSError, for photo: Photo) {
        photo.loadingState = .loadingFailed
        self.notificationCenter.post(name: .photoImageUpdate,
                                     object: photo,
                                     userInfo: [
                                        PhotosViewControllerNotification.ErrorKey: error,
                                        PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loadingFailed
                                     ])
    }
    
    func networkIntegration(_ networkIntegration: NetworkIntegration, didUpdateLoadingProgress percent: Double, for photo: Photo) {
        self.notificationCenter.post(name: .photoLoadingProgressUpdate,
                                     object: photo,
                                     userInfo: [PhotosViewControllerNotification.ProgressKey: percent])
    }

}

// MARK: - Photo extension
fileprivate var PhotoLoadingStateAssociationKey: UInt8 = 0
fileprivate var PhotoLoadingViewClassAssociationKey: UInt8 = 0
fileprivate extension Photo {
    
    var loadingState: PhotoLoadingState {
        get {
            return objc_getAssociatedObject(self, &PhotoLoadingStateAssociationKey) as? PhotoLoadingState ?? .notLoaded
        }
        set(value) {
            objc_setAssociatedObject(self, &PhotoLoadingStateAssociationKey, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var loadingViewClass: LoadingViewProtocol.Type? {
        get {
            return objc_getAssociatedObject(self, &PhotoLoadingViewClassAssociationKey) as? LoadingViewProtocol.Type
        }
        set(value) {
            objc_setAssociatedObject(self, &PhotoLoadingViewClassAssociationKey, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
}

// MARK: - PhotosViewControllerDelegate
@objc(BAPPhotosViewControllerDelegate) protocol PhotosViewControllerDelegate {
    
    #if !(BAP_SDWI_SUPPORT) && !(BAP_AFN_SUPPORT)
    /// Called when the PhotosViewController deems necessary (taking `numberOfPhotosToPreload` into account)
    /// to request the image defined in the photo object.
    ///
    /// - Parameters:
    ///   - viewController: The `PhotosViewController` requesting the image.
    ///   - photo: The related `Photo`.
    ///   - progressUpdateHandler: Call this (optional) handler to update the PhotosViewController about the progress of the image download.
    ///   - completionHandler: Call this handler to update the PhotosViewController that the image load has completed or failed.
    /// - Note: Loading is NOT handled by the PhotosViewController, this gives the developer an opportunity to store image data
    ///         independently of the PhotosViewController.
    /// - Note: The PhotosViewController will never request any photo's image more than once (except on failed loads).
    @objc(photosViewController:requestImageForPhoto:progressUpdateHandler:completionHandler:)
    func photosViewController(_ photosViewController: PhotosViewController,
                              requestImageFor photo: Photo,
                              progressUpdateHandler: ((_ photo: Photo, _ percentComplete: Double) -> Void),
                              _ completionHandler: (_ photo: Photo, _ error: NSError?) -> Void) -> Void
    #endif
    
    /// Called just before a new PhotosViewController is initialized. This custom `loadingView` must conform to `LoadingViewProtocol`.
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
@objc(BAPPhotosViewControllerNotification) class PhotosViewControllerNotification: NSObject {
    static let ProgressUpdate = Notification.Name.photoLoadingProgressUpdate.rawValue
    static let ImageUpdate = Notification.Name.photoImageUpdate.rawValue
    static let ImageKey = "BAPhotosViewControllerImage"
    static let ImageDataKey = "BAPhotosViewControllerImageData"
    static let LoadingStateKey = "BAPhotosViewControllerLoadingState"
    static let ProgressKey = "BAPhotosViewControllerProgress"
    static let ErrorKey = "BAPhotosViewControllerError"
}

extension Notification.Name {
    static let photoLoadingProgressUpdate = Notification.Name("BAPhotoLoadingProgressUpdateNotification")
    static let photoImageUpdate = Notification.Name("BAPhotoImageUpdateNotification")
}
