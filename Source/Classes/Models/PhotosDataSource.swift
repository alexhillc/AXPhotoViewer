//
//  PhotosConfiguration.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/1/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc(AXPhotosDataSource) open class PhotosDataSource: NSObject {
    
    @objc(AXPhotosPrefetchBehavior) public enum PhotosPrefetchBehavior: Int {
        case conservative = 0
        case regular      = 2
        case aggressive   = 4
    }
    
    /// The fetching behavior that the `PhotosViewController` should take action with.
    /// Setting this property to `conservative`, only the current photo will be loaded.
    /// Setting this property to `regular` (default), the current photo, the previous photo, and the next photo will be loaded.
    /// Setting this property to `aggressive`, the current photo, the previous two photos, and the next two photos will be loaded.
    @objc fileprivate(set) var prefetchBehavior: PhotosPrefetchBehavior
    
    /// The photos to display in the PhotosViewController.
    fileprivate var photos: [PhotoProtocol]
    
    // The initial photo index to display upon presentation.
    @objc fileprivate(set) var initialPhotoIndex: Int = 0
    
    // MARK: - Initialization
    @objc public init(photos: [PhotoProtocol], initialPhotoIndex: Int, prefetchBehavior: PhotosPrefetchBehavior) {
        self.photos = photos
        self.prefetchBehavior = prefetchBehavior
        
        if photos.count > 0 {
            assert(photos.count > initialPhotoIndex, "Invalid initial photo index provided.")
            self.initialPhotoIndex = initialPhotoIndex
        }
        
        super.init()
    }
    
    @objc public convenience override init() {
        self.init(photos: [], initialPhotoIndex: 0, prefetchBehavior: .regular)
    }
    
    @objc public convenience init(photos: [PhotoProtocol]) {
        self.init(photos: photos, initialPhotoIndex: 0, prefetchBehavior: .regular)
    }
    
    @objc public convenience init(photos: [PhotoProtocol], initialPhotoIndex: Int) {
        self.init(photos: photos, initialPhotoIndex: initialPhotoIndex, prefetchBehavior: .regular)
    }
    
    // MARK: - DataSource
    @objc public var numberOfPhotos: Int {
        return self.photos.count
    }
    
    @objc(photoAtIndex:)
    public func photo(at index: Int) -> PhotoProtocol? {
        if index < self.photos.count {
            return self.photos[index]
        }
        
        return nil
    }

}
