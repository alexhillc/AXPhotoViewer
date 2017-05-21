//
//  AFNetworkingIntegration.swift
//  Pods
//
//  Created by Alex Hill on 5/20/17.
//
//

import AFNetworking

class AFNetworkingIntegration: NSObject, NetworkIntegration {
    
    weak var delegate: NetworkIntegrationDelegate?
    
    func loadPhoto(_ photo: Photo) {
        if photo.imageData != nil || photo.image != nil {
            self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }
        
        guard let url = photo.url else {
            return
        }

        let success: (_ request: URLRequest, _ response: HTTPURLResponse?, _ image: UIImage) -> Void = { [weak self] (response, responseObject, error) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.networkIntegration(uSelf, loadDidFinishWith: photo)
        }
        
        let failure: (_ request: URLRequest, _ response: HTTPURLResponse?, _ error: Error) -> Void = { [weak self] (response, responseObject, error) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.networkIntegration(uSelf, loadDidFailWith: error, for: photo)
        }
        
        let urlRequest = URLRequest(url: url)
        AFImageDownloader.defaultInstance().downloadImage(for: urlRequest, success: success, failure: failure)
    }
    
}
