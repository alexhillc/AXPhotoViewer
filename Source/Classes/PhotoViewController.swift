//
//  PhotoViewController.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

import UIKit
import FLAnimatedImage

@objc(AXPhotoViewController) open class PhotoViewController: UIViewController, PageableViewControllerProtocol {
    
    public weak var delegate: PhotoViewControllerDelegate?
    public var pageIndex: Int = 0
    
    public var loadingView: LoadingViewProtocol? {
        didSet {
            (oldValue as? UIView)?.removeFromSuperview()
            self.view.setNeedsLayout()
        }
    }

    var zoomingImageView: ZoomingImageView {
        get {
            return self.view as! ZoomingImageView
        }
    }
    
    fileprivate var photo: PhotoProtocol?
    fileprivate weak var notificationCenter: NotificationCenter?
    
    public init(loadingView: LoadingViewProtocol, notificationCenter: NotificationCenter) {
        self.loadingView = loadingView
        self.notificationCenter = notificationCenter
        
        super.init(nibName: nil, bundle: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(photoLoadingProgressDidUpdate(_:)),
                                       name: .photoLoadingProgressUpdate,
                                       object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(photoImageDidUpdate(_:)),
                                       name: .photoImageUpdate,
                                       object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.notificationCenter?.removeObserver(self)
    }
    
    open override func loadView() {
        self.view = ZoomingImageView()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let loadingView = self.loadingView as? UIView {
            if loadingView.superview == nil {
                self.view.addSubview(loadingView)
            }
        }
        
        let loadingViewSize = self.loadingView?.sizeThatFits(self.view.bounds.size) ?? .zero
        (self.loadingView as? UIView)?.frame = CGRect(origin: CGPoint(x: (self.view.bounds.size.width - loadingViewSize.width) / 2,
                                                                      y: (self.view.bounds.size.height - loadingViewSize.height) / 2),
                                                      size: loadingViewSize)
        (self.loadingView as? UIView)?.setNeedsLayout()
    }
    
    public func applyPhoto(_ photo: PhotoProtocol) {
        self.photo = photo
        
        weak var weakSelf = self
        func resetImageView() {
            weakSelf?.zoomingImageView.image = nil
            weakSelf?.zoomingImageView.animatedImage = nil
        }
        
        switch photo.loadingState {
        case .loading, .notLoaded:
            resetImageView()
            self.loadingView?.removeError()
            self.loadingView?.startLoading(initialProgress: photo.progress)
        case .loadingFailed:
            resetImageView()
            let error = photo.error ?? NSError()
            self.loadingView?.showError(error, retryHandler: { [weak self] in
                guard let uSelf = self else {
                    return
                }
                
                self?.delegate?.photoViewController(uSelf, retryDownloadFor: photo)
                self?.loadingView?.removeError()
                self?.loadingView?.startLoading(initialProgress: photo.progress)
            })
        case .loaded:
            guard photo.image != nil || photo.imageData != nil else {
                assertionFailure("Must provide valid `UIImage` in \(#function)")
                return
            }
            
            self.loadingView?.removeError()
            self.loadingView?.stopLoading()
            
            if let imageData = photo.imageData {
                self.zoomingImageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
            } else if let image = photo.image {
                self.zoomingImageView.image = image
            }
        }
        
        self.view.setNeedsLayout()
    }
    
    // MARK: - PageableViewControllerProtocol
    func prepareForReuse() {
        self.zoomingImageView.image = nil
        self.zoomingImageView.animatedImage = nil
    }
    
    // MARK: - Notifications
    @objc fileprivate func photoLoadingProgressDidUpdate(_ notification: Notification) {
        guard let photo = notification.object as? PhotoProtocol else {
            assertionFailure("Photos must conform to the AXPhoto protocol.")
            return
        }
        
        guard photo === self.photo, let progress = notification.userInfo?[PhotosViewControllerNotification.ProgressKey] as? CGFloat else {
            return
        }
        
        self.loadingView?.updateProgress?(progress)
    }
    
    @objc fileprivate func photoImageDidUpdate(_ notification: Notification) {
        guard let photo = notification.object as? PhotoProtocol else {
            assertionFailure("Photos must conform to the AXPhoto protocol.")
            return
        }
        
        guard photo === self.photo, let userInfo = notification.userInfo else {
            return
        }
        
        if userInfo[PhotosViewControllerNotification.ImageDataKey] != nil || userInfo[PhotosViewControllerNotification.ImageKey] != nil {
            self.applyPhoto(photo)
        } else if let referenceView = userInfo[PhotosViewControllerNotification.ReferenceViewKey] as? FLAnimatedImageView {
            self.zoomingImageView.imageView.ax_syncFrames(with: referenceView)
        } else if let error = userInfo[PhotosViewControllerNotification.ErrorKey] as? Error {
            self.loadingView?.showError(error, retryHandler: { [weak self] in
                guard let uSelf = self, let photo = uSelf.photo else {
                    return
                }
                
                self?.delegate?.photoViewController(uSelf, retryDownloadFor: photo)
                self?.loadingView?.removeError()
                self?.loadingView?.startLoading(initialProgress: photo.progress)
                self?.view.setNeedsLayout()
            })
            
            self.view.setNeedsLayout()
        }
    }

}

@objc(AXPhotoViewControllerDelegate) public protocol PhotoViewControllerDelegate: AnyObject, NSObjectProtocol {
    
    @objc(photoViewController:retryDownloadForPhoto:)
    func photoViewController(_ photoViewController: PhotoViewController, retryDownloadFor photo: PhotoProtocol)
    
}
