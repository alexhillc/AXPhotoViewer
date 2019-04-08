//
//  AXPreviewingPhotosViewController.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 7/16/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

#if os(iOS)
import UIKit
import MobileCoreServices
import FLAnimatedImage

@objc open class AXPreviewingPhotosViewController: UIViewController, AXNetworkIntegrationDelegate {
    
    /// The photos to display in the `PhotosPreviewingViewController`.
    @objc open var dataSource: AXPhotosDataSource = AXPhotosDataSource() {
        didSet {
            // this can occur during `commonInit(dataSource:networkIntegration:)`
            if self.networkIntegration == nil {
                return
            }
            
            self.networkIntegration.cancelAllLoads()
            self.configure(with: dataSource.initialPhotoIndex)
        }
    }
    
    /// The `NetworkIntegration` passed in at initialization. This object is used to fetch images asynchronously from a cache or URL.
    /// - Initialized by the end of `commonInit(dataSource:networkIntegration:)`.
    @objc public fileprivate(set) var networkIntegration: AXNetworkIntegrationProtocol!
    
    var imageView: FLAnimatedImageView {
        get {
            return self.view as! FLAnimatedImageView
        }
    }
    
    // MARK: - Initialization
    @objc public init(dataSource: AXPhotosDataSource) {
        super.init(nibName: nil, bundle: nil)
        self.commonInit(dataSource: dataSource)
    }
    
    @objc public init(dataSource: AXPhotosDataSource,
                      networkIntegration: AXNetworkIntegrationProtocol) {
    
        super.init(nibName: nil, bundle: nil)
        self.commonInit(dataSource: dataSource,
                        networkIntegration: networkIntegration)
    }
    
    @objc public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func commonInit(dataSource: AXPhotosDataSource,
                                networkIntegration: AXNetworkIntegrationProtocol? = nil) {
        
        self.dataSource = dataSource

        var `networkIntegration` = networkIntegration
        if networkIntegration == nil {
            #if canImport(SDWebImage)
            networkIntegration = SDWebImageIntegration()
            #elseif canImport(PINRemoteImage)
            networkIntegration = PINRemoteImageIntegration()
            #elseif canImport(AFNetworking)
            networkIntegration = AFNetworkingIntegration()
            #elseif canImport(Kingfisher)
            networkIntegration = KingfisherIntegration()
            #elseif canImport(Nuke)
            networkIntegration = NukeIntegration()
            #else
            networkIntegration = SimpleNetworkIntegration()
            #endif
        }
        
        self.networkIntegration = networkIntegration
        self.networkIntegration.delegate = self
    }
    
    open override func loadView() {
        self.view = FLAnimatedImageView()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.contentMode = .scaleAspectFit
        self.configure(with: self.dataSource.initialPhotoIndex)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var newSize: CGSize
        if self.imageView.image == nil && self.imageView.animatedImage == nil {
            newSize = CGSize(width: self.imageView.frame.size.width,
                             height: self.imageView.frame.size.width * 9.0 / 16.0)
        } else {
            newSize = self.imageView.intrinsicContentSize
        }
        
        self.preferredContentSize = newSize
    }
    
    fileprivate func configure(with index: Int) {
        guard let photo = self.dataSource.photo(at: index) else { return }
        self.networkIntegration.loadPhoto(photo)
    }
    
    // MARK: - AXNetworkIntegrationDelegate
    public func networkIntegration(_ networkIntegration: AXNetworkIntegrationProtocol, loadDidFinishWith photo: AXPhotoProtocol) {
        if let animatedImage = photo.ax_animatedImage {
            photo.ax_loadingState = .loaded
            DispatchQueue.main.async { [weak self] in
                self?.imageView.animatedImage = animatedImage
                self?.view.setNeedsLayout()
            }
        } else if let imageData = photo.imageData, let animatedImage = FLAnimatedImage(animatedGIFData: imageData) {
            photo.ax_animatedImage = animatedImage
            photo.ax_loadingState = .loaded
            DispatchQueue.main.async { [weak self] in
                self?.imageView.animatedImage = animatedImage
                self?.view.setNeedsLayout()
            }
        } else if let image = photo.image {
            photo.ax_loadingState = .loaded
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image
                self?.view.setNeedsLayout()
            }
        }
    }
    
    public func networkIntegration(_ networkIntegration: AXNetworkIntegrationProtocol, loadDidFailWith error: Error, for photo: AXPhotoProtocol) {
        guard photo.ax_loadingState != .loadingCancelled else {
            return
        }
        
        photo.ax_loadingState = .loadingFailed
        photo.ax_error = error
    }
    
    public func networkIntegration(_ networkIntegration: AXNetworkIntegrationProtocol, didUpdateLoadingProgress progress: CGFloat, for photo: AXPhotoProtocol) {
        photo.ax_progress = progress
    }
    
}
#endif
