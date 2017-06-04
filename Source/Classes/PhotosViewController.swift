//
//  PhotosViewController.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

import UIKit
import MobileCoreServices

@objc(AXPhotosViewController) open class PhotosViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource,
                                                               PhotoViewControllerDelegate, NetworkIntegrationDelegate {
    
    public weak var delegate: PhotosViewControllerDelegate?
    
    /// The underlying `OverlayView` that is used for displaying photo captions, titles, and actions.
    public let overlayView = OverlayView()
    
    /// The photos to display in the PhotosViewController.
    public var dataSource: PhotosDataSource {
        didSet {
            self.networkIntegration.cancelAllLoads()
            self.configurePageViewController()
        }
    }
    
    /// The transition object used when animating presentation/dismissal transitions.
    /// If this object is not present, the presentation will revert to the iOS default.
    fileprivate(set) var transitionInfo: TransitionInfo?
    
    /// The configuration object applied to the internal pager at initialization.
    fileprivate(set) var pagingConfig: PagingConfig
    
    /// The underlying UIPageViewController that is used for swiping horizontally and vertically.
    /// - Important: `AXPhotosViewController` is this page view controller's `UIPageViewControllerDelegate`, `UIPageViewControllerDataSource`.
    ///              Changing these values will result in breakage.
    public let pageViewController: UIPageViewController
    
    /// The internal tap gesture recognizer that is used to hide/show the overlay interface.
    public let singleTapGestureRecognizer = UITapGestureRecognizer()
    
    #if AX_SDWEBIMAGE_SUPPORT
    public let networkIntegration: NetworkIntegration = SDWebImageIntegration()
    #elseif AX_PINREMOTEIMAGE_SUPPORT
    public let networkIntegration: NetworkIntegration = PINRemoteImageIntegration()
    #elseif AX_AFNETWORKING_SUPPORT
    public let networkIntegration: NetworkIntegration = AFNetworkingIntegration()
    #else
    public let networkIntegration: NetworkIntegration
    #endif
    
    // MARK: - Private variables
    fileprivate enum SwipeDirection {
        case none, left, right
    }
    
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
    
    fileprivate var _prefersStatusBarHidden: Bool = false
    open override var prefersStatusBarHidden: Bool {
        get {
            return _prefersStatusBarHidden
        }
        set {
            _prefersStatusBarHidden = newValue
        }
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    // MARK: - Initialization
    #if AX_SDWEBIMAGE_SUPPORT || AX_PINREMOTEIMAGE_SUPPORT || AX_AFNETWORKING_SUPPORT
    public init(dataSource: PhotosDataSource, transitionInfo: TransitionInfo? = nil, pagingConfig: PagingConfig = PagingConfig()) {
        self.pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                       navigationOrientation: pagingConfig.navigationOrientation,
                                                       options: [UIPageViewControllerOptionInterPageSpacingKey: pagingConfig.interPhotoSpacing])
        self.dataSource = dataSource
        self.transitionInfo = transitionInfo
        self.pagingConfig = pagingConfig
        super.init(nibName: nil, bundle: nil)
        self.networkIntegration.delegate = self
    }
    #else
    public init(dataSource: PhotosDataSource, transitionInfo: TransitionInfo? = nil, pagingConfig: PagingConfig = PagingConfig(), networkIntegration: NetworkIntegration) {
        self.pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                       navigationOrientation: pagingConfig.navigationOrientation,
                                                       options: [UIPageViewControllerOptionInterPageSpacingKey: pagingConfig.interPhotoSpacing])
        self.dataSource = dataSource
        self.transitionInfo = transitionInfo
        self.pagingConfig = pagingConfig
        self.networkIntegration = networkIntegration
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
        self.pageViewController.scrollView.removeContentOffsetObserver(self)
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.recycledViewControllers.removeLifeycleObserver(self)
        self.recycledLoadingViews.removeAll()
        self.recycledViewControllers.removeAll()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        self.pageViewController.scrollView.addContentOffsetObserver(self)
        
        self.singleTapGestureRecognizer.numberOfTapsRequired = 1
        self.singleTapGestureRecognizer.addTarget(self, action: #selector(singleTapAction(_:)))
        self.pageViewController.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
        
        self.configurePageViewController()
        
        self.overlayView.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAction(_:)))
        self.overlayView.tintColor = .white
        self.view.addSubview(self.overlayView)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.isSizeTransitioning = true
        coordinator.animate(alongsideTransition: nil) { [weak self] (context) in
            self?.isSizeTransitioning = false
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.pageViewController.view.frame = self.view.bounds
        self.overlayView.frame = self.view.bounds
        self.overlayView.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height,
                                                     left: 0,
                                                     bottom: 0, 
                                                     right: 0)
    }
    
    // MARK: - Page VC Configuration
    fileprivate func configurePageViewController() {
        guard let photo = self.dataSource.photo(at: self.dataSource.initialPhotoIndex),
              let photoViewController = self.makePhotoViewController(for: self.dataSource.initialPhotoIndex) else {
            self.pageViewController.setViewControllers(nil, direction: .forward, animated: false, completion: nil)
            return
        }
        
        photoViewController.applyPhoto(photo)
        photoViewController.pageIndex = self.dataSource.initialPhotoIndex
        self.pageViewController.setViewControllers([photoViewController], direction: .forward, animated: false, completion: nil)
        self.currentPhotoIndex = self.dataSource.initialPhotoIndex
        self.overlayView.titleView?.tweenBetweenLowIndex?(self.dataSource.initialPhotoIndex, highIndex: self.dataSource.initialPhotoIndex + 1, percent: 0)
        self.loadPhotos(at: self.dataSource.initialPhotoIndex)
    }
    
    // MARK: - Overlay and UIGestureRecognizerDelegate
    fileprivate func updateOverlay(for photoIndex: Int) {
        guard let photo = self.dataSource.photo(at: photoIndex) else {
            return
        }
        
        self.overlayView.title = NSLocalizedString("\(photoIndex + 1) of \(self.dataSource.numberOfPhotos)", comment: "")
        self.overlayView.captionView.applyCaptionInfo(attributedTitle: photo.attributedTitle ?? nil,
                                                      attributedDescription: photo.attributedDescription ?? nil,
                                                      attributedCredit: photo.attributedCredit ?? nil)
    }
    
    @objc fileprivate func shareAction(_ barButtonItem: UIBarButtonItem) {
        guard let photo = self.dataSource.photo(at: self.currentPhotoIndex) else {
            return
        }
        
        if let _ = self.delegate?.photosViewController?(self, handleActionButtonTappedFor: photo) {
            return
        }

        var anyRepresentation: Any?
        if let imageData = photo.imageData {
            anyRepresentation = imageData
        } else if let image = photo.image {
            anyRepresentation = image
        }
        
        guard let uAnyRepresentation = anyRepresentation else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [uAnyRepresentation], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, activityError) in
            guard let uSelf = self else {
                return
            }
            
            if completed, let activityType = activityType {
                uSelf.delegate?.photosViewController?(uSelf, actionCompletedWith: activityType, for: photo)
            }
        }
        
        if self.traitCollection.userInterfaceIdiom == .phone {
            self.present(activityViewController, animated: true)
        } else {
            activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
            self.present(activityViewController, animated: true)
        }
    }
    
    @objc fileprivate func singleTapAction(_ sender: UITapGestureRecognizer) {
        let showInterface = (self.overlayView.alpha == 0)
        self.overlayView.setShowInterface(showInterface) { [weak self] in
            self?.prefersStatusBarHidden = !showInterface
            self?.setNeedsStatusBarAppearanceUpdate()
            if showInterface {
                UIView.performWithoutAnimation {
                    self?.overlayView.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height,
                                                                  left: 0,
                                                                  bottom: 0,
                                                                  right: 0)
                    self?.overlayView.setNeedsLayout()
                    self?.overlayView.layoutIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Loading helpers
    fileprivate func loadPhotos(at index: Int) {
        let numberOfPhotosToLoad = self.dataSource.prefetchBehavior.rawValue
        let startIndex = (((index - (numberOfPhotosToLoad / 2)) >= 0) ? (index - (numberOfPhotosToLoad / 2)) : 0)
        let indexes = startIndex..<(startIndex + numberOfPhotosToLoad + 1)
        
        for index in indexes {
            guard let photo = self.dataSource.photo(at: index) else {
                return
            }
            
            if photo.loadingState == .notLoaded {
                photo.loadingState = .loading
                self.networkIntegration.loadPhoto(photo)
            }
        }
    }
    
    fileprivate func cancelLoadForPhotos(at index: Int) {
        let numberOfPhotosToLoad = self.dataSource.prefetchBehavior.rawValue
        let lowerIndex = (index - (numberOfPhotosToLoad / 2) - 1 >= 0) ? index - (numberOfPhotosToLoad / 2) - 1: NSNotFound
        let upperIndex = (index + (numberOfPhotosToLoad / 2) + 1 < self.dataSource.numberOfPhotos) ? index + (numberOfPhotosToLoad / 2) + 1 : NSNotFound
        
        weak var weakSelf = self
        func cancelLoadIfNecessary(for photo: PhotoProtocol) {
            guard let uSelf = weakSelf, photo.loadingState == .loading else {
                return
            }
            
            uSelf.networkIntegration.cancelLoad(for: photo)
            photo.loadingState = .notLoaded
        }
        
        if lowerIndex != NSNotFound, let photo = self.dataSource.photo(at: lowerIndex) {
            cancelLoadIfNecessary(for: photo)
        }
        
        if upperIndex != NSNotFound, let photo = self.dataSource.photo(at: upperIndex) {
            cancelLoadIfNecessary(for: photo)
        }
    }
    
    // MARK: - Reuse / Factory
    fileprivate func makePhotoViewController(for pageIndex: Int) -> PhotoViewController? {
        guard let photo = self.dataSource.photo(at: pageIndex) else {
            return nil
        }
        
        var photoViewController: PhotoViewController
        
        if self.recycledViewControllers.count > 0 {
            photoViewController = self.recycledViewControllers.removeLast()
            photoViewController.loadingView = self.makeLoadingView(for: pageIndex)
            photoViewController.prepareForReuse()
        } else {
            guard let loadingView = self.makeLoadingView(for: pageIndex) else {
                return nil
            }
            
            photoViewController = PhotoViewController(loadingView: loadingView, notificationCenter: self.notificationCenter)
            photoViewController.addLifecycleObserver(self)
            photoViewController.delegate = self
            
            self.singleTapGestureRecognizer.require(toFail: photoViewController.zoomingImageView.doubleTapGestureRecognizer)
        }
        
        photoViewController.pageIndex = pageIndex
        photoViewController.applyPhoto(photo)
        
        let insertionIndex = self.orderedViewControllers.insertionIndex(of: photoViewController, isOrderedBefore: { $0.pageIndex < $1.pageIndex })
        if !insertionIndex.alreadyExists {
            self.orderedViewControllers.insert(photoViewController, at: insertionIndex.index)
        }
        
        return photoViewController
    }
    
    fileprivate func makeLoadingView(for pageIndex: Int) -> LoadingViewProtocol? {
        guard let photo = self.dataSource.photo(at: pageIndex) else {
            return nil
        }
        
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
    
    // MARK: - KVO
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &PhotoViewControllerLifecycleContext {
            self.lifecycleContextDidUpdate(object: object, change: change)
        } else if context == &PhotoViewControllerContentOffsetContext {
            self.contentOffsetContextDidUpdate(object: object, change: change)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    fileprivate func lifecycleContextDidUpdate(object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        guard let photoViewController = object as? PhotoViewController else {
            return
        }
        
        if change?[.newKey] is NSNull {
            self.delegate?.photosViewController?(self, prepareViewControllerForEndDisplay: photoViewController)
            self.recyclePhotoViewController(photoViewController)
        } else {
            self.delegate?.photosViewController?(self, prepareViewControllerForDisplay: photoViewController)
        }
    }
    
    fileprivate func contentOffsetContextDidUpdate(object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        guard let scrollView = object as? UIScrollView, !self.isSizeTransitioning else {
            return
        }
        
        var percent: CGFloat
        if self.pagingConfig.navigationOrientation == .horizontal {
            percent = (scrollView.contentOffset.x - scrollView.frame.size.width) / scrollView.frame.size.width
        } else {
            percent = (scrollView.contentOffset.y - scrollView.frame.size.height) / scrollView.frame.size.height
        }
        
        var horizontalSwipeDirection: SwipeDirection = .none
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
                if lowIndex < self.dataSource.numberOfPhotos {
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
        
        self.overlayView.titleView?.tweenBetweenLowIndex?(lowIndex, highIndex: highIndex, percent: percent)
    }
    
    fileprivate func computeVisibleViewControllers(in referenceView: UIScrollView) -> [PhotoViewController] {
        var visibleViewControllers = [PhotoViewController]()
        
        for viewController in self.orderedViewControllers {
            guard !viewController.view.frame.equalTo(.zero) else {
                continue
            }
            
            let origin = CGPoint(x: viewController.view.frame.origin.x - (self.pagingConfig.navigationOrientation == .horizontal ?
                                                                          (self.pagingConfig.interPhotoSpacing / 2) : 0),
                                 y: viewController.view.frame.origin.y - (self.pagingConfig.navigationOrientation == .vertical ?
                                                                          (self.pagingConfig.interPhotoSpacing / 2) : 0))
            let size = CGSize(width: viewController.view.frame.size.width + ((self.pagingConfig.navigationOrientation == .horizontal) ?
                                                                             self.pagingConfig.interPhotoSpacing : 0),
                              height: viewController.view.frame.size.height + ((self.pagingConfig.navigationOrientation == .vertical) ?
                                                                               self.pagingConfig.interPhotoSpacing : 0))
            let conversionRect = CGRect(origin: origin, size: size)
            
            if referenceView.convert(conversionRect, from: viewController.view.superview).intersects(referenceView.bounds) {
                visibleViewControllers.append(viewController)
            }
        }
        
        return visibleViewControllers
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
        guard index >= 0 && self.dataSource.numberOfPhotos > index else {
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
    
    public func networkIntegration(_ networkIntegration: NetworkIntegration, didUpdateLoadingProgress progress: CGFloat, for photo: PhotoProtocol) {
        photo.progress = progress
        self.notificationCenter.post(name: .photoLoadingProgressUpdate,
                                     object: photo,
                                     userInfo: [PhotosViewControllerNotification.ProgressKey: progress])
    }

}

// MARK: - Convenience extensions
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
    
    var scrollView: UIScrollView {
        get {
            guard let scrollView = self.view.subviews.filter({ $0 is UIScrollView }).first as? UIScrollView else {
                fatalError("Unable to locate the underlying `UIScrollView`")
            }
            
            return scrollView
        }
    }
    
}

fileprivate var PhotoViewControllerContentOffsetContext: UInt8 = 0
fileprivate extension UIScrollView {
    
    func addContentOffsetObserver(_ observer: NSObject) -> Void {
        self.addObserver(observer, forKeyPath: #keyPath(contentOffset), options: .new, context: &PhotoViewControllerContentOffsetContext)
    }
    
    func removeContentOffsetObserver(_ observer: NSObject) -> Void {
        self.removeObserver(observer, forKeyPath: #keyPath(contentOffset), context: &PhotoViewControllerContentOffsetContext)
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
    
    /// Called when the action button is tapped for a photo. If no implementation is provided, will fall back to default action.
    ///
    /// - Parameters:
    ///   - photosViewController: The `PhotosViewController` handling the action.
    ///   - photo: The related `Photo`.
    @objc(photosViewController:handleActionButtonTappedForPhoto:)
    optional func photosViewController(_ photosViewController: PhotosViewController, handleActionButtonTappedFor photo: PhotoProtocol)
    
    /// Called when an action button action is completed.
    ///
    /// - Parameters:
    ///   - photosViewController: The `PhotosViewController` that handled the action.
    ///   - photo: The related `Photo`.
    @objc(photosViewController:actionCompletedWithActivityType:forPhoto:)
    optional func photosViewController(_ photosViewController: PhotosViewController, actionCompletedWith activityType: UIActivityType, for photo: PhotoProtocol)
}

// MARK: - Notification definitions
// Keep Obj-C land happy
@objc(AXPhotosViewControllerNotification) open class PhotosViewControllerNotification: NSObject {
    static let ProgressUpdate = Notification.Name.photoLoadingProgressUpdate.rawValue
    static let ImageUpdate = Notification.Name.photoImageUpdate.rawValue
    static let ImageKey = "AXPhotosViewControllerImage"
    static let ImageDataKey = "AXPhotosViewControllerImageData"
    static let LoadingStateKey = "AXPhotosViewControllerLoadingState"
    static let ProgressKey = "AXPhotosViewControllerProgress"
    static let ErrorKey = "AXPhotosViewControllerError"
}

public extension Notification.Name {
    static let photoLoadingProgressUpdate = Notification.Name("AXPhotoLoadingProgressUpdateNotification")
    static let photoImageUpdate = Notification.Name("AXPhotoImageUpdateNotification")
}
