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
    
    func loadPhoto(_ photo: Photo) {
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
            
            uSelf.delegate?.networkIntegration?(uSelf, didUpdateLoadingProgress: Double(receivedSize / expectedSize), for: photo)
        }
        
        let completion: SDWebImageDownloaderCompletedBlock = { [weak self] (image, data, error, finished) in
            guard let uSelf = self else {
                return
            }
            
            if let error = error {
                uSelf.delegate?.networkIntegration(uSelf, loadDidFailWith: error, for: photo)
            } else if let _ = image, let _ = data, finished {
                uSelf.delegate?.networkIntegration(uSelf, loadDidFinishWith: photo)
            }
        }
        
        SDWebImageDownloader.shared().downloadImage(with: url, options: [], progress: progress, completed: completion)
    }
    
}
