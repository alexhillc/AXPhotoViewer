//
//  NukeIntegration.swift
//  AXPhotoViewer
//
//  Created by Alessandro Nakamuta on 15/04/18.
//  Copyright © 2018 Alessandro Nakamuta. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(Nuke)
import Nuke

class NukeIntegration: NSObject, AXNetworkIntegrationProtocol {

    weak public var delegate: AXNetworkIntegrationDelegate?

    fileprivate var retrieveImageTasks = NSMapTable<AXPhotoProtocol, ImageTask>(keyOptions: .strongMemory, valueOptions: .strongMemory)

    public func loadPhoto(_ photo: AXPhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
            }
            return
        }

        guard let url = photo.url else { return }
        
        let progress: ImageTask.ProgressHandler = { [weak self] (_, receivedSize, totalSize) in
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(receivedSize) / CGFloat(totalSize), for: photo)
            }
        }
        
        let completion: ImageTask.Completion = { [weak self] (response, error) in
            guard let `self` = self else { return }
            
            self.retrieveImageTasks.removeObject(forKey: photo)
            
            if let imageData = response?.image.animatedImageData {
                photo.imageData = imageData
                AXDispatchUtils.executeInBackground { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
                }
            } else if let image = response?.image {
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
        
        let task = ImagePipeline.shared.loadImage(with: url, progress: progress, completion: completion)
        self.retrieveImageTasks.setObject(task, forKey: photo)
    }

    func cancelLoad(for photo: AXPhotoProtocol) {
        guard let downloadTask = self.retrieveImageTasks.object(forKey: photo) else { return }
        downloadTask.cancel()
    }

    func cancelAllLoads() {
        let enumerator = self.retrieveImageTasks.objectEnumerator()

        while let downloadTask = enumerator?.nextObject() as? ImageTask {
            downloadTask.cancel()
        }

        self.retrieveImageTasks.removeAllObjects()
    }

}
#endif
