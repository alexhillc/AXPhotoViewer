//
//  AXNetworkIntegrationProtocol.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/20/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

let AXNetworkIntegrationErrorDomain = "AXNetworkIntegrationErrorDomain"
let AXNetworkIntegrationFailedToLoadErrorCode = 6

@objc public protocol AXNetworkIntegrationProtocol: AnyObject, NSObjectProtocol {
    
    @objc var delegate: AXNetworkIntegrationDelegate? { get set }
    
    /// This function should load a provided photo, calling all necessary `AXNetworkIntegrationDelegate` delegate methods.
    ///
    /// - Parameter photo: The photo to load.
    @objc func loadPhoto(_ photo: AXPhotoProtocol)
    
    /// This function should cancel the load (if possible) for the provided photo.
    ///
    /// - Parameter photo: The photo load to cancel.
    @objc func cancelLoad(for photo: AXPhotoProtocol)
    
    /// This function should cancel all current photo loads.
    @objc func cancelAllLoads()
    
}

@objc public protocol AXNetworkIntegrationDelegate: AnyObject, NSObjectProtocol {
    
    /// Called when a `AXPhoto` successfully finishes loading.
    ///
    /// - Parameters:
    ///   - networkIntegration: The `NetworkIntegration` that was performing the load.
    ///   - photo: The related `Photo`.
    /// - Note: This method is expected to be called on a background thread. Be mindful of this when retrieving items from a memory cache.
    @objc func networkIntegration(_ networkIntegration: AXNetworkIntegrationProtocol,
                                  loadDidFinishWith photo: AXPhotoProtocol)
    
    /// Called when a `AXPhoto` fails to load.
    ///
    /// - Parameters:
    ///   - networkIntegration: The `NetworkIntegration` that was performing the load.
    ///   - error: The error that the load failed with.
    ///   - photo: The related `Photo`.
    /// - Note: This method is expected to be called on a background thread.
    @objc func networkIntegration(_ networkIntegration: AXNetworkIntegrationProtocol,
                                  loadDidFailWith error: Error,
                                  for photo: AXPhotoProtocol)
    
    /// Called when a `AXPhoto`'s loading progress is updated.
    ///
    /// - Parameters:
    ///   - networkIntegration: The `NetworkIntegration` that is performing the load.
    ///   - progress: The progress of the `AXPhoto` load represented as a percentage. Exists on a scale from 0..1. 
    ///   - photo: The related `AXPhoto`.
    /// - Note: This method is expected to be called on a background thread.
    @objc optional func networkIntegration(_ networkIntegration: AXNetworkIntegrationProtocol,
                                           didUpdateLoadingProgress progress: CGFloat,
                                           for photo: AXPhotoProtocol)
    
}
