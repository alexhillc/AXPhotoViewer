//
//  SDWebImageIntegration.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/20/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(SDWebImage)
import SDWebImage

class SDWebImageIntegration: NSObject, AXNetworkIntegrationProtocol {
    
    weak var delegate: AXNetworkIntegrationDelegate?
    
    fileprivate var downloadOperations = NSMapTable<AXPhotoProtocol, SDWebImageOperation>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    
    func loadPhoto(_ photo: AXPhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
            }
            return
        }
        
        guard let url = photo.url else { return }
                
        let progress: SDWebImageDownloaderProgressBlock = { [weak self] (receivedSize, expectedSize, targetURL) in
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(receivedSize) / CGFloat(expectedSize), for: photo)
            }
        }
        
        let completion: SDInternalCompletionBlock = { [weak self] (image, data, error, cacheType, finished, imageURL) in
            guard let `self` = self else { return }
            
            self.downloadOperations.removeObject(forKey: photo)
            
            if let data = data, data.containsGIF() {
                photo.imageData = data
                AXDispatchUtils.executeInBackground { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
                }
            } else if let image = image {
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
        
        guard let operation = SDWebImageManager.shared.loadImage(with: url, options: [], progress: progress, completed: completion) else { return }
        self.downloadOperations.setObject(operation, forKey: photo)
    }
    
    func cancelLoad(for photo: AXPhotoProtocol) {
        guard let downloadOperation = self.downloadOperations.object(forKey: photo) else { return }
        downloadOperation.cancel()
    }
    
    func cancelAllLoads() {
        let enumerator = self.downloadOperations.objectEnumerator()
        
        while let downloadOperation = enumerator?.nextObject() as? SDWebImageOperation {
            downloadOperation.cancel()
        }
        
        self.downloadOperations.removeAllObjects()
    }
    
}
#endif
