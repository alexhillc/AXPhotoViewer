//
//  KingfisherIntegration.swift
//  AXPhotoViewer
//
//  Created by Matt Lamont on 11/08/17.
//  Copyright © 2017 Matt Lamont. All rights reserved.
//

#if canImport(Kingfisher)
import Kingfisher

class KingfisherIntegration: NSObject, AXNetworkIntegrationProtocol {
    
    weak public var delegate: AXNetworkIntegrationDelegate?
    
    fileprivate var retrieveImageTasks: [Int: DownloadTask] = [:]
    
    public func loadPhoto(_ photo: AXPhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
            }
            return
        }
        
        guard let url = photo.url else { return }
        
        let progress: DownloadProgressBlock = { [weak self] (receivedSize, totalSize) in
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(receivedSize) / CGFloat(totalSize), for: photo)
            }
        }
        
        let completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void) = { [weak self] (result) in
            guard let `self` = self else { return }
            
            self.retrieveImageTasks[photo.hash] = nil
            
            switch result {
            case .success(let retrieveImageResult):
                if let imageData = retrieveImageResult.image.kf.gifRepresentation() {
                    photo.imageData = imageData
                    AXDispatchUtils.executeInBackground { [weak self] in
                        guard let `self` = self else { return }
                        self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
                    }
                } else {
                    photo.image = retrieveImageResult.image
                    AXDispatchUtils.executeInBackground { [weak self] in
                        guard let `self` = self else { return }
                        self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
                    }
                }
            case .failure(let error):
                let error = NSError(
                    domain: AXNetworkIntegrationErrorDomain,
                    code: AXNetworkIntegrationFailedToLoadErrorCode,
                    userInfo: ["description": error.errorDescription ?? ""]
                )
                AXDispatchUtils.executeInBackground { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.networkIntegration(self, loadDidFailWith: error, for: photo)
                }
            }
        }
        
        let task = KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: progress, completionHandler: completion)
        self.retrieveImageTasks[photo.hash] = task
    }
    
    func cancelLoad(for photo: AXPhotoProtocol) {
        guard let downloadTask = self.retrieveImageTasks[photo.hash] else { return }
        downloadTask.cancel()
    }
    
    func cancelAllLoads() {
        self.retrieveImageTasks.forEach({ $1.cancel() })
        self.retrieveImageTasks.removeAll()
    }
    
}
#endif
