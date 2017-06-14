//
//  SimpleNetworkIntegration.swift
//  Pods
//
//  Created by Alex Hill on 6/11/17.
//
//

open class SimpleNetworkIntegration: NSObject, NetworkIntegration, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    fileprivate var urlSession: URLSession!
    public weak var delegate: NetworkIntegrationDelegate?
    
    fileprivate var receivedData = [Int: Data]()
    fileprivate var receivedContentLength = [Int: Int64]()
    
    fileprivate var dataTasks = NSMapTable<PhotoProtocol, URLSessionDataTask>(keyOptions: .strongMemory, valueOptions: .strongMemory)
    fileprivate var photos = [Int: PhotoProtocol]()
    
    override public init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    public func loadPhoto(_ photo: PhotoProtocol) {
        if photo.imageData != nil || photo.image != nil {
            self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
        }
        
        guard let url = photo.url else {
            return
        }
        
        let dataTask = self.urlSession.dataTask(with: url)
        self.dataTasks.setObject(dataTask, forKey: photo)
        self.photos[dataTask.taskIdentifier] = photo
        dataTask.resume()
    }
    
    public func cancelLoad(for photo: PhotoProtocol) {
        guard let dataTask = self.dataTasks.object(forKey: photo) else {
            return
        }
        
        dataTask.cancel()
    }
    
    public func cancelAllLoads() {
        let enumerator = self.dataTasks.objectEnumerator()
        
        while let dataTask = enumerator?.nextObject() as? URLSessionDataTask {
            dataTask.cancel()
        }
        
        self.dataTasks.removeAllObjects()
        self.receivedData.removeAll()
        self.receivedContentLength.removeAll()
        self.photos.removeAll()
    }
    
    // MARK: - URLSessionDataDelegate
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData[dataTask.taskIdentifier]?.append(data)
        
        guard let receivedData = self.receivedData[dataTask.taskIdentifier],
            let expectedContentLength = self.receivedContentLength[dataTask.taskIdentifier],
            let photo = self.photos[dataTask.taskIdentifier] else {
            return
        }
        
        self.delegate?.networkIntegration?(self, didUpdateLoadingProgress: CGFloat(receivedData.count) / CGFloat(expectedContentLength),
                                           for: photo)
    }
    
    public func urlSession(_ session: URLSession, 
                           dataTask: URLSessionDataTask,
                           didReceive response: URLResponse, 
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        self.receivedContentLength[dataTask.taskIdentifier] = response.expectedContentLength
        self.receivedData[dataTask.taskIdentifier] = Data()
        completionHandler(.allow)
    }
    
    // MARK: - URLSessionTaskDelegate
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let photo = self.photos[task.taskIdentifier] else {
            return
        }
        
        weak var weakSelf = self
        func removeData() {
            weakSelf?.photos.removeValue(forKey: task.taskIdentifier)
            weakSelf?.receivedData.removeValue(forKey: task.taskIdentifier)
            weakSelf?.receivedContentLength.removeValue(forKey: task.taskIdentifier)
            weakSelf?.dataTasks.removeObject(forKey: photo)
        }
        
        if let error = error {
            self.delegate?.networkIntegration(self, loadDidFailWith: error, for: photo)
            removeData()
            return
        }
        
        guard let data = self.receivedData[task.taskIdentifier] else {
            return
        }
        
        if data.containsGIF() {
            photo.imageData = data
        } else {
            photo.image = UIImage(data: data)
        }
        
        removeData()
        self.delegate?.networkIntegration(self, loadDidFinishWith: photo)
    }

}
