//
//  AFNetworkingIntegration.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/20/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AFNetworking)
import AFNetworking
import ImageIO

class AFNetworkingIntegration: NSObject, AXNetworkIntegrationProtocol {
    
    weak public var delegate: AXNetworkIntegrationDelegate?
    
    fileprivate var downloadTasks = NSMapTable<AXPhotoProtocol, URLSessionDataTask>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    
    public func loadPhoto(_ photo: AXPhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
            }
            return
        }
        
        guard let url = photo.url else {
            return
        }
        
        let progress: (_ progress: Progress) -> Void = { [weak self] (progress) in
            AXDispatchUtils.executeInBackground { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(progress.fractionCompleted), for: photo)
            }
        }

        let success: (_ dataTask: URLSessionDataTask, _ responseObject: Any?) -> Void = { [weak self] (dataTask, responseObject) in
            guard let `self` = self else { return }
            
            self.downloadTasks.removeObject(forKey: photo)
            
            if let responseGIFData = responseObject as? Data {
                photo.imageData = responseGIFData
                AXDispatchUtils.executeInBackground { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
                }
            } else if let responseImage = responseObject as? UIImage {
                photo.image = responseImage
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
        
        let failure: (_ dataTask: URLSessionDataTask?, _ error: Error) -> Void = { [weak self] (dataTask, error) in
            guard let `self` = self else { return }
            
            self.downloadTasks.removeObject(forKey: photo)
            
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
        
        guard let dataTask = AXHTTPSessionManager.shared.get(url.absoluteString,
                                                             parameters: nil,
                                                             progress: progress,
                                                             success: success,
                                                             failure: failure) else { return }
        self.downloadTasks.setObject(dataTask, forKey: photo)
    }
    
    func cancelLoad(for photo: AXPhotoProtocol) {
        guard let dataTask = self.downloadTasks.object(forKey: photo) else { return }
        
        dataTask.cancel()
        self.downloadTasks.removeObject(forKey: photo)
    }
    
    func cancelAllLoads() {
        let enumerator = self.downloadTasks.objectEnumerator()
        
        while let dataTask = enumerator?.nextObject() as? URLSessionDataTask {
            dataTask.cancel()
        }
        
        self.downloadTasks.removeAllObjects()
    }
    
}

/// An `AFHTTPSesssionManager` with our subclassed `AXImageResponseSerializer`.
class AXHTTPSessionManager: AFHTTPSessionManager {
    
    static let shared = AXHTTPSessionManager()
    
    init() {
        super.init(baseURL: nil, sessionConfiguration: .default)
        self.responseSerializer = AXImageResponseSerializer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

/// A subclassed `AFImageResponseSerializer` that returns GIF data if it exists.
class AXImageResponseSerializer: AFImageResponseSerializer {
    
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        if let `data` = data, data.containsGIF() { return data }
        return super.responseObject(for: response, data: data, error: error)
    }
    
}
#endif
