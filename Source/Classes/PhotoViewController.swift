//
//  PhotoViewController.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

import UIKit
import FLAnimatedImage

@objc(BAPPhotoViewController) public class PhotoViewController: UIViewController, Recyclable {
    
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
    
    fileprivate var photo: Photo?
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
    
    public override func loadView() {
        self.view = ZoomingImageView()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let loadingView = self.loadingView as? UIView {
            if loadingView.superview == nil {
                self.view.addSubview(loadingView)
            }
        }
        
        (self.loadingView as? UIView)?.frame = self.view.bounds
    }
    
    public func applyPhoto(_ photo: Photo) {
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
            guard let image = photo.image else {
                assertionFailure("Must provide valid `UIImage` in \(#function)")
                return
            }
            
            self.loadingView?.removeError()
            self.loadingView?.stopLoading()
            
            if let imageData = photo.imageData {
                if image.isGIF() {
                    self.zoomingImageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
                } else {
                    self.zoomingImageView.image = UIImage(data: imageData)
                }
            } else {
                self.zoomingImageView.image = image
            }
        }
    }
    
    // MARK: - Recyclable
    public func prepareForReuse() {
        self.zoomingImageView.maximumZoomScale = 1
        self.zoomingImageView.minimumZoomScale = 1
        self.zoomingImageView.zoomScale = 1
    }
    
    // MARK: - Notifications
    @objc fileprivate func photoLoadingProgressDidUpdate(_ notification: Notification) {
        guard let photo = notification.object as? Photo else {
            assertionFailure("Photos must conform to the BAPPhoto protocol.")
            return
        }
        
        guard photo === self.photo, let progress = notification.userInfo?[PhotosViewControllerNotification.ProgressKey] as? Progress else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.loadingView?.updateProgress?(progress)
        }
    }
    
    @objc fileprivate func photoImageDidUpdate(_ notification: Notification) {
        guard let photo = notification.object as? Photo else {
            assertionFailure("Photos must conform to the BAPPhoto protocol.")
            return
        }
        
        guard photo === self.photo else {
            return
        }
        
        if notification.userInfo?[PhotosViewControllerNotification.ImageDataKey] != nil ||
            notification.userInfo?[PhotosViewControllerNotification.ImageKey] != nil {
            
            DispatchQueue.main.async { [weak self] in
                self?.applyPhoto(photo)
            }
        } else if let error = notification.userInfo?[PhotosViewControllerNotification.ErrorKey] as? Error {
            DispatchQueue.main.async { [weak self] in
                self?.loadingView?.showError(error, retryHandler: {
                    guard let uSelf = self, let photo = uSelf.photo else {
                        return
                    }
                    
                    self?.delegate?.photoViewController(uSelf, retryDownloadFor: photo)
                    self?.loadingView?.removeError()
                    self?.loadingView?.startLoading(initialProgress: photo.progress)
                })
            }
        }
    }

}

@objc(BAPPhotoViewControllerDelegate) public protocol PhotoViewControllerDelegate: AnyObject, NSObjectProtocol {
    
    @objc(photoViewController:retryDownloadForPhoto:)
    func photoViewController(_ photoViewController: PhotoViewController, retryDownloadFor photo: Photo)
    
}
