//
//  PhotosViewController.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

import UIKit

private enum PhotoLoadingState: Int {
    case notLoaded, loading, loaded, loadingFailed
}

@objc(BAPPhotosViewController) class PhotosViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    weak var delegate: PhotosViewControllerDelegate?
    
    /// The photos to display in the PhotosViewController.
    var photos: [Photo] {
        didSet {
            self.photoLoadingStates.removeAll()
            self.setup(withInitialIndex: 0)
        }
    }
    
    /// The class of the loading view to be instantiated upon PhotoViewController initialization.
    /// - Important: `loadingViewClass` must conform to the `LoadingViewProtocol` in order for PhotosViewController to function properly.
    var loadingViewClass: AnyClass? {
        didSet(value) {
            assert(value is LoadingViewProtocol, "`loadingViewClass` must conform to the `LoadingViewProtocol` in order for PhotosViewController to function properly.")
        }
    }
    
    /// The number of photos to load surrounding the currently displayed photo.
    var numberOfPhotosToPreload: Int = 2
    
    /// The underlying UIPageViewController that is used for swiping horizontally.
    let pageViewController = UIPageViewController()
    
    fileprivate var photoLoadingStates = [Int: PhotoLoadingState]()
    fileprivate let notificationCenter = NotificationCenter()
    fileprivate var recycledViewControllers = [PhotoViewController]()
    
    init(photos: [Photo], initialIndex: Int = 0, delegate: PhotosViewControllerDelegate) {
        self.delegate = delegate
        self.photos = photos
        assert(photos.count > initialIndex, "Invalid initial page index provided.")
        super.init(nibName: nil, bundle: nil)
        self.setup(withInitialIndex: initialIndex)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setup(withInitialIndex initialIndex: Int) {
        let photoViewController = self.photoViewController(configuredForPageIndex: initialIndex)
        photoViewController.applyPhoto(photos[initialIndex])
        photoViewController.pageIndex = initialIndex
        self.pageViewController.setViewControllers([photoViewController], direction: .forward, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.pageViewController.view.frame = self.view.bounds
    }
    
    fileprivate func photoViewController(configuredForPageIndex pageIndex: Int) -> PhotoViewController {
        let photo = self.photos[pageIndex]
        var vc: PhotoViewController
        
        if self.recycledViewControllers.count > 0 {
            vc = self.recycledViewControllers.removeLast()
        } else {
            var loadingView: LoadingViewProtocol
            if let loadingViewClass = self.loadingViewClass as? NSObject.Type {
                loadingView = loadingViewClass.init() as! LoadingViewProtocol
            } else {
                loadingView = LoadingView()
            }
            
            vc = PhotoViewController(loadingView: loadingView, notificationCenter: self.notificationCenter)
        }
        
        vc.pageIndex = pageIndex
        vc.applyPhoto(photo)
        
        return vc
    }
    
    fileprivate func loadPhotos(atIndex index: Int) {
        let startIndex = (index - (self.numberOfPhotosToPreload / 2))
        let indexes = ((startIndex >= 0) ? startIndex: 0)..<(self.numberOfPhotosToPreload + 1)
        
        for index in indexes {
            guard self.photos.count > index else {
                return
            }
            
            weak var weakSelf = self

            let progressUpdateHandler: (_ photo: Photo, _ progress: Double) -> Void = { (photo, progress) in
                weakSelf?.notificationCenter.post(name: .photoLoadingProgressUpdate,
                                                  object: photo,
                                                  userInfo: [PhotosViewControllerNotification.ProgressKey: progress])
            }
            
            let photoLoadingState = self.photoLoadingStates[index] ?? .notLoaded
            if photoLoadingState != .loading && photoLoadingState != .loaded {
                self.photoLoadingStates[index] = .loading
                
                let photo = self.photos[index]
                self.delegate?.photosViewController(viewController: self,
                                                    requestImageForPhoto: photo,
                                                    progressUpdateHandler: progressUpdateHandler, { (photo, image, error) in
                    if let image = image {
                        weakSelf?.photoLoadingStates[index] = .loaded
                        weakSelf?.notificationCenter.post(name: .photoImageUpdate,
                                                          object: photo,
                                                          userInfo: [
                                                            PhotosViewControllerNotification.ImageKey: image,
                                                            PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loaded
                                                          ])
                    } else if let error = error {
                        weakSelf?.photoLoadingStates[index] = .loadingFailed
                        weakSelf?.notificationCenter.post(name: .photoImageUpdate,
                                                          object: photo,
                                                          userInfo: [
                                                            PhotosViewControllerNotification.ErrorKey: error,
                                                            PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loadingFailed
                                                          ])
                    }
                })
            }
        }
        
    }
    
    // MARK: - UIPageViewControllerDelegate
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard finished, let photoViewControllers = previousViewControllers as? [PhotoViewController] else {
            return
        }
        
        self.recycledViewControllers.append(contentsOf: photoViewControllers)
    }
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let photoViewController = viewController as? PhotoViewController else {
            assertionFailure("Paging VC must be a subclass of PhotoViewController.")
            return nil
        }
        
        let pageIndex = photoViewController.pageIndex - 1
        guard pageIndex >= 0 && self.photos.count > pageIndex else {
            return nil
        }
        
        self.loadPhotos(atIndex: pageIndex)
        
        return self.photoViewController(configuredForPageIndex: pageIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let photoViewController = viewController as? PhotoViewController else {
            assertionFailure("Paging VC must be a subclass of PhotoViewController.")
            return nil
        }
        
        let pageIndex = photoViewController.pageIndex + 1
        guard self.photos.count > pageIndex else {
            return nil
        }
        
        self.loadPhotos(atIndex: pageIndex)
        
        return self.photoViewController(configuredForPageIndex: pageIndex)
    }

}

// MARK: - Notification definitions
// Keep Obj-C land happy
@objc(BAPPhotosViewControllerNotification) class PhotosViewControllerNotification: NSObject {
    static let ProgressUpdate = Notification.Name.photoLoadingProgressUpdate.rawValue
    static let ImageUpdate = Notification.Name.photoImageUpdate.rawValue
    static let ImageKey = "BAPhotosViewControllerImage"
    static let LoadingStateKey = "BAPhotosViewControllerLoadingState"
    static let ProgressKey = "BAPhotosViewControllerProgress"
    static let ErrorKey = "BAPhotosViewControllerError"
}

extension Notification.Name {
    static let photoLoadingProgressUpdate = Notification.Name("BAPhotoLoadingProgressUpdateNotification")
    static let photoImageUpdate = Notification.Name("BAPhotoImageUpdateNotification")
}

// MARK: - PhotosViewControllerDelegate
@objc(BAPPhotosViewControllerDelegate) protocol PhotosViewControllerDelegate {
    
    /// Called when the PhotosViewController deems necessary to request the image defined in the photo object.
    ///
    /// - Parameters:
    ///   - viewController: The `PhotosViewController` requesting the image.
    ///   - photo: The related `Photo`.
    ///   - progressUpdateHandler: Call this (optional) handler to update the PhotosViewController about the progress of the image download.
    ///   - completionHandler: Call this handler to update the PhotosViewController that the image load has completed or failed.
    /// - Note: Loading is NOT handled by the PhotosViewController, this gives the developer an opportunity to store image data
    ///         independently of the PhotosViewController.
    /// - Note: The PhotosViewController will never request any photo's image more than once (except for failed loads).
    @objc func photosViewController(viewController: PhotosViewController,
                                    requestImageForPhoto photo: Photo,
                                    progressUpdateHandler: ((_ photo: Photo, _ percentComplete: Double) -> Void),
                                    _ completionHandler: (_ photo: Photo, _ image: UIImage?, _ error: NSError?) -> Void) -> Void

}
