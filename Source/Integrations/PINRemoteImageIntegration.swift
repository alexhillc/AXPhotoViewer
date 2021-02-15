//
//  PINRemoteImageIntegration.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/1/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(PINRemoteImage)
import PINRemoteImage

class PINRemoteImageIntegration: NSObject, AXNetworkIntegrationProtocol, PINRemoteImageManagerAlternateRepresentationProvider {

    weak var delegate: AXNetworkIntegrationDelegate?
    
    fileprivate var downloadUUIDs = NSMapTable<AXPhotoProtocol, NSUUID>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    fileprivate(set) var imageManager: PINRemoteImageManager!
    
    override init() {
        super.init()
        self.imageManager = PINRemoteImageManager(
            sessionConfiguration: .default,
            alternativeRepresentationProvider: self,
            imageCache: PINRemoteImageManager.shared().cache // PINRemoteImageManager cache is thread safe, so we should be able to use the same cache instance as our shared counterpart
        )
    }
    
    func loadPhoto(_ photo: AXPhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
            }
            return
        }
        
        guard let url = photo.url else { return }
        
        let progress: PINRemoteImageManagerProgressDownload = { [weak self] (completedBytes, totalBytes) in
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(completedBytes) / CGFloat(totalBytes), for: photo)
            }
        }
        
        let completion: PINRemoteImageManagerImageCompletion = { [weak self] (result) in
            guard let `self` = self else { return }
            
            self.downloadUUIDs.removeObject(forKey: photo)
            
            if let data = result.alternativeRepresentation as? Data {
                photo.imageData = data
                AXDispatchUtils.executeInBackground { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
                }
            } else if let image = result.image {
                photo.image = image
                AXDispatchUtils.executeInBackground { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
                }
            } else {
                let error = NSError(
                    domain: AXNetworkIntegrationErrorDomain,
                    code: AXNetworkIntegrationFailedToLoadErrorCode,
                    userInfo: nil
                )
                AXDispatchUtils.executeInBackground { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.networkIntegration(self, loadDidFailWith: error, for: photo)
                }
            }
        }
        
        guard let uuid = self.imageManager.downloadImage(with: url, options: [], progressDownload: progress, completion: completion) else { return }
        self.downloadUUIDs.setObject(uuid as NSUUID, forKey: photo)
    }
    
    func cancelLoad(for photo: AXPhotoProtocol) {
        guard let uuid = self.downloadUUIDs.object(forKey: photo) else { return }
        self.imageManager.cancelTask(with: uuid as UUID, storeResumeData: true)
    }
    
    func cancelAllLoads() {
        let enumerator = self.downloadUUIDs.objectEnumerator()
        
        while let uuid  = enumerator?.nextObject() as? NSUUID {
            self.imageManager.cancelTask(with: uuid as UUID, storeResumeData: true)
        }
        
        self.downloadUUIDs.removeAllObjects()
    }
    
    // MARK: - PINRemoteImageManagerAlternateRepresentationProvider
    func alternateRepresentation(with data: Data!, options: PINRemoteImageManagerDownloadOptions = []) -> Any! {
        guard let `data` = data else { return nil }
        return data.containsGIF() ? data : nil
    }
    
}
#endif
