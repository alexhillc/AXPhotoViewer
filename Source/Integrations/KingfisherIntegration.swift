//
//  KingfisherIntegration.swift
//  AXPhotoViewer
//
//  Created by Matt Lamont on 11/08/17.
//  Copyright © 2017 Matt Lamont. All rights reserved.
//

import Kingfisher

class KingfisherIntegration: NSObject, NetworkIntegrationProtocol {

    weak public var delegate: NetworkIntegrationDelegate?

    fileprivate var downloadTasks = NSMapTable<PhotoProtocol, RetrieveImageTask>(keyOptions: .strongMemory, valueOptions: .strongMemory)

    public func loadPhoto(_ photo: PhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }

        guard let url = photo.url else {
            return
        }

        let progress: DownloadProgressBlock = { [weak self] (receivedSize, totalSize) in
            guard let uSelf = self else {
                return
            }

            uSelf.delegate?.networkIntegration?(uSelf, didUpdateLoadingProgress: CGFloat(totalSize / receivedSize), for: photo)
        }

        let completion: CompletionHandler = { [weak self] (image, error, cacheType, imageURL) in
            guard let uSelf = self else {
                return
            }

            self?.downloadTasks.removeObject(forKey: photo)

            if let error = error {
                uSelf.delegate?.networkIntegration(uSelf, loadDidFailWith: error, for: photo)
            } else {
                if let image = image {
                    photo.image = image
                }

                uSelf.delegate?.networkIntegration(uSelf, loadDidFinishWith: photo)
            }
        }

        let task = KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: progress, completionHandler: completion)
        self.downloadTasks.setObject(task, forKey: photo)
    }

    func cancelLoad(for photo: PhotoProtocol) {
        guard let downloadTask = self.downloadTasks.object(forKey: photo) else {
            return
        }

        downloadTask.cancel()

    }

    func cancelAllLoads() {
        let enumerator = self.downloadTasks.objectEnumerator()

        while let downloadTask = enumerator?.nextObject() as? RetrieveImageTask {
            downloadTask.cancel()
        }

        self.downloadTasks.removeAllObjects()
    }
    
}
