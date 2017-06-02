//
//  PhotosConfiguration.swift
//  Pods
//
//  Created by Alex Hill on 6/1/17.
//
//

@objc(AXPhotosDataSource) open class PhotosDataSource: NSObject {
    
    @objc(AXPhotosFetchingBehavior) public enum PhotosFetchingBehavior: Int {
        case conservative = 0
        case regular      = 2
        case aggressive   = 4
    }
    
    /// The fetching behavior that the `PhotosViewController` should take action with.
    /// Setting this property to `conservative`, only the current photo will be loaded.
    /// Setting this property to `regular` (default), the current photo, the previous photo, and the next photo will be loaded.
    /// Setting this property to `aggressive`, the current photo, the previous two photos, and the next two photos will be loaded.
    fileprivate(set) var photosFetchingBehavior: PhotosFetchingBehavior
    
    /// The photos to display in the PhotosViewController.
    fileprivate var photos: [PhotoProtocol]
    
    // The initial photo index to display upon presentation.
    private(set) var initialPhotoIndex: Int = 0
    
    // MARK: - Initialization
    public init(photos: [PhotoProtocol], initialPhotoIndex: Int? = nil, photosFetchingBehavior: PhotosFetchingBehavior = .regular) {
        self.photos = photos
        self.photosFetchingBehavior = photosFetchingBehavior
        
        if let initialPhotoIndex = initialPhotoIndex {
            assert(photos.count > initialPhotoIndex, "Invalid initial photo index provided.")
            self.initialPhotoIndex = initialPhotoIndex
        }
        
        super.init()
    }
    
    // MARK: - DataSource
    var numberOfPhotos: Int {
        return self.photos.count
    }
    
    public func photo(at index: Int) -> PhotoProtocol? {
        if index < self.photos.count {
            return self.photos[index]
        }
        
        return nil
    }

}
