//
//  AFNetworkingIntegration.swift
//  Pods
//
//  Created by Alex Hill on 5/20/17.
//
//

import AFNetworking
import ImageIO

class AFNetworkingIntegration: NSObject, NetworkIntegration {
    
    weak public var delegate: NetworkIntegrationDelegate?
    
    fileprivate var downloadTasks = NSMapTable<PhotoProtocol, URLSessionDataTask>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    
    public func loadPhoto(_ photo: PhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }
        
        guard let url = photo.url else {
            return
        }
        
        let progress: (_ progress: Progress) -> Void = { [weak self] (progress) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.networkIntegration?(uSelf, didUpdateLoadingProgress: CGFloat(progress.fractionCompleted), for: photo)
        }

        let success: (_ dataTask: URLSessionDataTask, _ responseObject: Any?) -> Void = { [weak self] (dataTask, responseObject) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.downloadTasks.removeObject(forKey: photo)
            
            if let responseGIFData = responseObject as? Data {
                photo.imageData = responseGIFData
            } else if let responseImage = responseObject as? UIImage {
                photo.image = responseImage
            }
            
            uSelf.delegate?.networkIntegration(uSelf, loadDidFinishWith: photo)
        }
        
        let failure: (_ dataTask: URLSessionDataTask?, _ error: Error) -> Void = { [weak self] (dataTask, error) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.downloadTasks.removeObject(forKey: photo)
            uSelf.delegate?.networkIntegration(uSelf, loadDidFailWith: error, for: photo)
        }
        
        guard let dataTask = AXAFHTTPSessionManager.shared.get(url.absoluteString, parameters: nil, progress: progress, success: success, failure: failure) else {
            return
        }
        
        self.downloadTasks.setObject(dataTask, forKey: photo)
    }
    
    func cancelLoad(for photo: PhotoProtocol) {
        guard let dataTask = self.downloadTasks.object(forKey: photo) else {
            return
        }
        
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

/// An `AFHTTPSesssionManager` with our subclassed `AXAFImageResponseSerializer`.
class AXAFHTTPSessionManager: AFHTTPSessionManager {
    
    static let shared = AXAFHTTPSessionManager()
    
    init() {
        super.init(baseURL: nil, sessionConfiguration: .default)
        self.responseSerializer = AXAFImageResponseSerializer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

/// A subclassed `AFImageResponseSerializer` that returns GIF data if it exists.
class AXAFImageResponseSerializer: AFImageResponseSerializer {
    
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        guard let imageSourceData = data as CFData? else {
            return super.responseObject(for: response, data: data, error: error)
        }
        
        let options: [String: Any] = [kCGImageSourceShouldCache as String: false]
        guard let imageSource = CGImageSourceCreateWithData(imageSourceData, options as CFDictionary?),
            let imageSourceContainerType = CGImageSourceGetType(imageSource)else {
                
            return super.responseObject(for: response, data: data, error: error)
        }
        
        let isGIFData = UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF)
        if isGIFData {
            return data
        }
        
        return super.responseObject(for: response, data: data, error: error)
    }
    
}
