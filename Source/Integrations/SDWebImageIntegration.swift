//
//  SDWebImageIntegration.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/20/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import SDWebImage

class SDWebImageIntegration: NSObject, NetworkIntegrationProtocol {
    
    weak var delegate: NetworkIntegrationDelegate?
    
    fileprivate var downloadOperations = NSMapTable<PhotoProtocol, SDWebImageOperation>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    
    func loadPhoto(_ photo: PhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }
        
        guard let url = photo.url else {
            return
        }
                
        let progress: SDWebImageDownloaderProgressBlock = { [weak self] (receivedSize, expectedSize, targetURL) in
            guard let `self` = self else {
                return
            }
            
            self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(receivedSize) / CGFloat(expectedSize), for: photo)
        }
        
        let completion: SDInternalCompletionBlock = { [weak self] (image, data, error, cacheType, finished, imageURL) in
            guard let `self` = self else {
                return
            }
            
            self.downloadOperations.removeObject(forKey: photo)
            
            if let error = error {
                self.delegate?.networkIntegration(self, loadDidFailWith: error, for: photo)
            } else {
                if let image = image {
                    if image.isGIF() {
                        photo.imageData = data
                    }
                    photo.image = image
                } else if let imageData = data {
                    photo.imageData = imageData
                }
                
                self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
            }
        }
        
        guard let operation = SDWebImageManager.shared().loadImage(with: url, options: [], progress: progress, completed: completion) else {
            return
        }
        
        self.downloadOperations.setObject(operation, forKey: photo)
    }
    
    func cancelLoad(for photo: PhotoProtocol) {
        guard let downloadOperation = self.downloadOperations.object(forKey: photo) else {
            return
        }
        
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
