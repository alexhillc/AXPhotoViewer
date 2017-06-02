//
//  SDWebImageIntegration.swift
//  Pods
//
//  Created by Alex Hill on 5/20/17.
//
//

import SDWebImage

class SDWebImageIntegration: NSObject, NetworkIntegration {
    
    weak var delegate: NetworkIntegrationDelegate?
    
    fileprivate var downloadTokens = NSMapTable<PhotoProtocol, SDWebImageDownloadToken>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    
    func loadPhoto(_ photo: PhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }
        
        guard let url = photo.url else {
            return
        }
        
        let progress: SDWebImageDownloaderProgressBlock = { [weak self] (receivedSize, expectedSize, targetURL) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.networkIntegration?(uSelf, didUpdateLoadingProgress: CGFloat(receivedSize / expectedSize), for: photo)
        }
        
        let completion: SDWebImageDownloaderCompletedBlock = { [weak self] (image, data, error, finished) in
            guard let uSelf = self else {
                return
            }
            
            self?.downloadTokens.removeObject(forKey: photo)
            
            if let error = error {
                uSelf.delegate?.networkIntegration(uSelf, loadDidFailWith: error, for: photo)
            } else if let image = image, let data = data, finished {
                if image.isAnimatedGIF() {
                    photo.imageData = data
                    photo.image = image
                } else {
                    photo.image = image
                }
                
                uSelf.delegate?.networkIntegration(uSelf, loadDidFinishWith: photo)
            }
        }
        
        guard let token = SDWebImageDownloader.shared().downloadImage(with: url, options: [], progress: progress, completed: completion) else {
            return
        }
        
        self.downloadTokens.setObject(token, forKey: photo)
    }
    
    func cancelLoad(for photo: PhotoProtocol) {
        guard let token = self.downloadTokens.object(forKey: photo) else {
            return
        }
        
        SDWebImageDownloader.shared().cancel(token)
    }
    
    func cancelAllLoads() {
        let enumerator = self.downloadTokens.objectEnumerator()
        
        while let downloadToken = enumerator?.nextObject() as? SDWebImageDownloadToken {
            SDWebImageDownloader.shared().cancel(downloadToken)
        }
    }
    
}
