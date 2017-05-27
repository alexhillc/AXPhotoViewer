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
    
    fileprivate var downloadTokens = NSMapTable<Photo, SDWebImageDownloadToken>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    
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
            
            let progress = Progress(totalUnitCount: Int64(expectedSize))
            progress.completedUnitCount = Int64(receivedSize)
            uSelf.delegate?.networkIntegration?(uSelf, didUpdateLoadingProgress: progress, for: photo)
        }
        
        let completion: SDWebImageDownloaderCompletedBlock = { [weak self] (image, data, error, finished) in
            guard let uSelf = self else {
                return
            }
            
            self?.downloadTokens.removeObject(forKey: photo)
            
            if let error = error {
                uSelf.delegate?.networkIntegration(uSelf, loadDidFailWith: error, for: photo)
            } else if let image = image, let data = data, finished {
                if image.isGIF() {
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
    
    func cancelLoad(for photo: Photo) {
        guard let token = self.downloadTokens.object(forKey: photo) else {
            return
        }
        
        SDWebImageDownloader.shared().cancel(token)
    }
    
}
