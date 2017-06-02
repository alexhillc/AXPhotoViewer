//
//  AFNetworkingIntegration.swift
//  Pods
//
//  Created by Alex Hill on 5/20/17.
//
//

import AFNetworking

class AFNetworkingIntegration: NSObject, NetworkIntegration {
    
    weak public var delegate: NetworkIntegrationDelegate?
    
    fileprivate var downloadReceipts = NSMapTable<PhotoProtocol, AFImageDownloadReceipt>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    
    public func loadPhoto(_ photo: PhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }
        
        guard let url = photo.url else {
            return
        }

        let success: (_ request: URLRequest, _ response: HTTPURLResponse?, _ image: UIImage) -> Void = { [weak self] (response, responseObject, image) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.downloadReceipts.removeObject(forKey: photo)
            photo.image = image
            uSelf.delegate?.networkIntegration(uSelf, loadDidFinishWith: photo)
        }
        
        let failure: (_ request: URLRequest, _ response: HTTPURLResponse?, _ error: Error) -> Void = { [weak self] (response, responseObject, error) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.downloadReceipts.removeObject(forKey: photo)
            uSelf.delegate?.networkIntegration(uSelf, loadDidFailWith: error, for: photo)
        }
        
        let urlRequest = URLRequest(url: url)
        guard let receipt = AFImageDownloader.defaultInstance().downloadImage(for: urlRequest, success: success, failure: failure) else {
            return
        }
        
        self.downloadReceipts.setObject(receipt, forKey: photo)
    }
    
    func cancelLoad(for photo: PhotoProtocol) {
        guard let receipt = self.downloadReceipts.object(forKey: photo) else {
            return
        }
        
        AFImageDownloader.defaultInstance().cancelTask(for: receipt)
        self.downloadReceipts.removeObject(forKey: photo)
    }
    
    func cancelAllLoads() {
        let enumerator = self.downloadReceipts.objectEnumerator()
        
        while let receipt = enumerator?.nextObject() as? AFImageDownloadReceipt {
            AFImageDownloader.defaultInstance().cancelTask(for: receipt)
        }
        
        self.downloadReceipts.removeAllObjects()
    }
    
}
