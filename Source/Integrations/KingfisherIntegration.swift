//
//  KingfisherIntegration.swift
//  AXPhotoViewer
//
//  Created by Matt Lamont on 11/08/17.
//  Copyright © 2017 Matt Lamont. All rights reserved.
//

import Kingfisher

class KingfisherIntegration: NSObject, AXNetworkIntegrationProtocol {

    weak public var delegate: AXNetworkIntegrationDelegate?

    fileprivate var retrieveImageTasks = NSMapTable<AXPhotoProtocol, RetrieveImageTask>(keyOptions: .strongMemory, valueOptions: .strongMemory)

    public func loadPhoto(_ photo: AXPhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }

        guard let url = photo.url else {
            return
        }

        let progress: DownloadProgressBlock = { [weak self] (receivedSize, totalSize) in
            guard let `self` = self else {
                return
            }

            self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(receivedSize) / CGFloat(totalSize), for: photo)
        }

        let completion: CompletionHandler = { [weak self] (image, error, cacheType, imageURL) in
            guard let `self` = self else {
                return
            }

            self.retrieveImageTasks.removeObject(forKey: photo)

            if let error = error {
                self.delegate?.networkIntegration(self, loadDidFailWith: error, for: photo)
            } else {
                if let image = image {
                    if let imageData = image.kf.gifRepresentation() {
                        photo.imageData = imageData
                    }
                    
                    photo.image = image
                }

                self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
            }
        }

        let task = KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: progress, completionHandler: completion)
        self.retrieveImageTasks.setObject(task, forKey: photo)
    }

    func cancelLoad(for photo: AXPhotoProtocol) {
        guard let downloadTask = self.retrieveImageTasks.object(forKey: photo) else {
            return
        }

        downloadTask.cancel()
    }

    func cancelAllLoads() {
        let enumerator = self.retrieveImageTasks.objectEnumerator()

        while let downloadTask = enumerator?.nextObject() as? RetrieveImageTask {
            downloadTask.cancel()
        }

        self.retrieveImageTasks.removeAllObjects()
    }
    
}
