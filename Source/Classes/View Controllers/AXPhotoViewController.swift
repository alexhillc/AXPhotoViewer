//
//  AXPhotoViewController.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/7/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit

#if os(iOS)
import FLAnimatedImage
#elseif os(tvOS)
import FLAnimatedImage_tvOS
#endif

@objc open class AXPhotoViewController: UIViewController, AXPageableViewControllerProtocol, AXZoomingImageViewDelegate {
    
    @objc public weak var delegate: AXPhotoViewControllerDelegate?
    @objc public var pageIndex: Int = 0
    
    @objc fileprivate(set) var loadingView: AXLoadingViewProtocol?

    var zoomingImageView: AXZoomingImageView {
        get {
            return self.view as! AXZoomingImageView
        }
    }
    
    fileprivate var photo: AXPhotoProtocol?
    fileprivate weak var notificationCenter: NotificationCenter?
    
    @objc public init(loadingView: AXLoadingViewProtocol, notificationCenter: NotificationCenter) {
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
    
    @objc public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.notificationCenter?.removeObserver(self)
    }
    
    open override func loadView() {
        self.view = AXZoomingImageView()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.zoomingImageView.zoomScaleDelegate = self
        
        if let loadingView = self.loadingView as? UIView {
            self.view.addSubview(loadingView)
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var adjustedSize = self.view.bounds.size
        if #available(iOS 11.0, tvOS 11.0, *) {
            adjustedSize.width -= (self.view.safeAreaInsets.left + self.view.safeAreaInsets.right)
            adjustedSize.height -= (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom)
        }
        
        let loadingViewSize = self.loadingView?.sizeThatFits(adjustedSize) ?? .zero
        (self.loadingView as? UIView)?.frame = CGRect(origin: CGPoint(x: floor((self.view.bounds.size.width - loadingViewSize.width) / 2),
                                                                      y: floor((self.view.bounds.size.height - loadingViewSize.height) / 2)),
                                                      size: loadingViewSize)
    }
    
    @objc public func applyPhoto(_ photo: AXPhotoProtocol) {
        self.photo = photo
        
        weak var weakSelf = self
        func resetImageView() {
            weakSelf?.zoomingImageView.image = nil
            weakSelf?.zoomingImageView.animatedImage = nil
        }
        
        self.loadingView?.removeError()
        
        switch photo.ax_loadingState {
        case .loading, .notLoaded, .loadingCancelled:
            resetImageView()
            self.loadingView?.startLoading(initialProgress: photo.ax_progress)
        case .loadingFailed:
            resetImageView()
            let error = photo.ax_error ?? NSError()
            self.loadingView?.showError(error, retryHandler: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.delegate?.photoViewController(self, retryDownloadFor: photo)
                self.loadingView?.removeError()
                self.loadingView?.startLoading(initialProgress: photo.ax_progress)
            })
        case .loaded:
            guard photo.image != nil || photo.ax_animatedImage != nil else {
                assertionFailure("Must provide valid `UIImage` in \(#function)")
                return
            }
            
            self.loadingView?.stopLoading()
            
            if let animatedImage = photo.ax_animatedImage {
                self.zoomingImageView.animatedImage = animatedImage
            } else if let image = photo.image {
                self.zoomingImageView.image = image
            }
        }
        
        self.view.setNeedsLayout()
    }
    
    // MARK: - AXPageableViewControllerProtocol
    func prepareForReuse() {
        self.zoomingImageView.image = nil
        self.zoomingImageView.animatedImage = nil
    }
    
    // MARK: - AXZoomingImageViewDelegate
    func zoomingImageView(_ zoomingImageView: AXZoomingImageView, maximumZoomScaleFor imageSize: CGSize) -> CGFloat {
        return self.delegate?.photoViewController(self,
                                                  maximumZoomScaleForPhotoAt: self.pageIndex,
                                                  minimumZoomScale: zoomingImageView.minimumZoomScale,
                                                  imageSize: imageSize) ?? .leastNormalMagnitude
    }
    
    // MARK: - Notifications
    @objc fileprivate func photoLoadingProgressDidUpdate(_ notification: Notification) {
        guard let photo = notification.object as? AXPhotoProtocol else {
            assertionFailure("Photos must conform to the AXPhoto protocol.")
            return
        }
        
        guard photo === self.photo, let progress = notification.userInfo?[AXPhotosViewControllerNotification.ProgressKey] as? CGFloat else {
            return
        }
        
        self.loadingView?.updateProgress?(progress)
    }
    
    @objc fileprivate func photoImageDidUpdate(_ notification: Notification) {
        guard let photo = notification.object as? AXPhotoProtocol else {
            assertionFailure("Photos must conform to the AXPhoto protocol.")
            return
        }
        
        guard photo === self.photo, let userInfo = notification.userInfo else {
            return
        }
        
        if userInfo[AXPhotosViewControllerNotification.AnimatedImageKey] != nil || userInfo[AXPhotosViewControllerNotification.ImageKey] != nil {
            self.applyPhoto(photo)
        } else if let referenceView = userInfo[AXPhotosViewControllerNotification.ReferenceViewKey] as? FLAnimatedImageView {
            self.zoomingImageView.imageView.ax_syncFrames(with: referenceView)
        } else if let error = userInfo[AXPhotosViewControllerNotification.ErrorKey] as? Error {
            self.loadingView?.showError(error, retryHandler: { [weak self] in
                guard let `self` = self, let photo = self.photo else {
                    return
                }
                
                self.delegate?.photoViewController(self, retryDownloadFor: photo)
                self.loadingView?.removeError()
                self.loadingView?.startLoading(initialProgress: photo.ax_progress)
                self.view.setNeedsLayout()
            })
            
            self.view.setNeedsLayout()
        }
    }

}

@objc public protocol AXPhotoViewControllerDelegate: AnyObject, NSObjectProtocol {
    
    @objc(photoViewController:retryDownloadForPhoto:)
    func photoViewController(_ photoViewController: AXPhotoViewController, retryDownloadFor photo: AXPhotoProtocol)
    
    @objc(photoViewController:maximumZoomScaleForPhotoAtIndex:minimumZoomScale:imageSize:)
    func photoViewController(_ photoViewController: AXPhotoViewController,
                             maximumZoomScaleForPhotoAt index: Int,
                             minimumZoomScale: CGFloat,
                             imageSize: CGSize) -> CGFloat
    
}
