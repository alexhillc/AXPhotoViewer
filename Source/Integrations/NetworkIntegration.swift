//
//  NetworkIntegration.swift
//  Pods
//
//  Created by Alex Hill on 5/20/17.
//
//

@objc(AXNetworkIntegration) public protocol NetworkIntegration: AnyObject, NSObjectProtocol {
    
    weak var delegate: NetworkIntegrationDelegate? { get set }
    
    /// This function should load a provided photo, calling all necessary `NetworkIntegrationDelegate` delegate methods.
    ///
    /// - Parameter photo: The photo to load.
    func loadPhoto(_ photo: PhotoProtocol)
    
    
    /// This function should cancel the load (if possible) for the provided photo.
    ///
    /// - Parameter photo: The photo load to cancel.
    func cancelLoad(for photo: PhotoProtocol)
    
    /// This function should cancel all current photo loads.
    func cancelAllLoads()
    
}

@objc(AXNetworkIntegrationDelegate) public protocol NetworkIntegrationDelegate: class {
    
    /// Called when a `Photo` successfully finishes loading.
    ///
    /// - Parameters:
    ///   - networkIntegration: The `NetworkIntegration` that was performing the load.
    ///   - photo: The related `Photo`.
    func networkIntegration(_ networkIntegration: NetworkIntegration,
                            loadDidFinishWith photo: PhotoProtocol)
    
    
    /// Called when a `Photo` fails to load.
    ///
    /// - Parameters:
    ///   - networkIntegration: The `NetworkIntegration` that was performing the load.
    ///   - error: The error that the load failed with.
    ///   - photo: The related `Photo`.
    func networkIntegration(_ networkIntegration: NetworkIntegration,
                            loadDidFailWith error: Error,
                            for photo: PhotoProtocol)
    
    /// Called when a `Photo`'s loading progress is updated.
    ///
    /// - Parameters:
    ///   - networkIntegration: The `NetworkIntegration` that is performing the load.
    ///   - percent: The progress of the `Photo` load represented as a percentage.
    ///   - photo: The related `Photo`.
    @objc optional func networkIntegration(_ networkIntegration: NetworkIntegration,
                                           didUpdateLoadingProgress progress: Progress,
                                           for photo: PhotoProtocol)
    
}
