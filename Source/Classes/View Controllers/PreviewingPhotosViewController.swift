//
//  PreviewingPhotosViewController.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 7/16/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import FLAnimatedImage
import MobileCoreServices

@objc(AXPreviewingPhotosViewController) open class PreviewingPhotosViewController: UIViewController,
                                                                                   NetworkIntegrationDelegate {
    
    /// The photos to display in the `PhotosPreviewingViewController`.
    @objc open var dataSource: PhotosDataSource = PhotosDataSource() {
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
    @objc public fileprivate(set) var networkIntegration: NetworkIntegrationProtocol!
    
    var imageView: FLAnimatedImageView {
        get {
            return self.view as! FLAnimatedImageView
        }
    }
    
    // MARK: - Initialization
    #if AX_SDWEBIMAGE_SUPPORT || AX_PINREMOTEIMAGE_SUPPORT || AX_AFNETWORKING_SUPPORT || AX_KINGFISHER_SUPPORT || AX_LITE_SUPPORT
    @objc public init(dataSource: PhotosDataSource) {
        super.init(nibName: nil, bundle: nil)
        self.commonInit(dataSource: dataSource)
    }
    #else
    @objc public init(dataSource: PhotosDataSource,
                      networkIntegration: NetworkIntegrationProtocol) {
    
        super.init(nibName: nil, bundle: nil)
        self.commonInit(dataSource: dataSource,
                        networkIntegration: networkIntegration)
    }
    #endif
    
    @objc public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func commonInit(dataSource: PhotosDataSource,
                                networkIntegration: NetworkIntegrationProtocol? = nil) {
        
        self.dataSource = dataSource

        var uNetworkIntegration: NetworkIntegrationProtocol!
        if networkIntegration == nil {
            #if AX_SDWEBIMAGE_SUPPORT
                uNetworkIntegration = SDWebImageIntegration()
            #elseif AX_PINREMOTEIMAGE_SUPPORT
                uNetworkIntegration = PINRemoteImageIntegration()
            #elseif AX_AFNETWORKING_SUPPORT
                uNetworkIntegration = AFNetworkingIntegration()
            #elseif AX_KINGFISHER_SUPPORT
                uNetworkIntegration = KingfisherIntegration()
            #elseif AX_LITE_SUPPORT
                uNetworkIntegration = SimpleNetworkIntegration()
            #else
                fatalError("Must be using one of the network integration subspecs if no `NetworkIntegration` is going to be provided.")
            #endif
        }
        
        self.networkIntegration = uNetworkIntegration
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
        guard let photo = self.dataSource.photo(at: index) else {
            return
        }
        
        self.networkIntegration.loadPhoto(photo)
    }
    
    // MARK: - NetworkIntegrationDelegate
    public func networkIntegration(_ networkIntegration: NetworkIntegrationProtocol, loadDidFinishWith photo: PhotoProtocol) {
        if let imageData = photo.imageData {
            photo.ax_loadingState = .loaded
            DispatchQueue.main.async { [weak self] in
                self?.imageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
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
    
    public func networkIntegration(_ networkIntegration: NetworkIntegrationProtocol, loadDidFailWith error: Error, for photo: PhotoProtocol) {
        guard photo.ax_loadingState != .loadingCancelled else {
            return
        }
        
        photo.ax_loadingState = .loadingFailed
        photo.ax_error = error
    }
    
    public func networkIntegration(_ networkIntegration: NetworkIntegrationProtocol, didUpdateLoadingProgress progress: CGFloat, for photo: PhotoProtocol) {
        photo.ax_progress = progress
    }
    
}
