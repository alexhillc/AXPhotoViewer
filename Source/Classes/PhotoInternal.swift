//
//  PhotoInternal.swift
//  Pods
//
//  Created by Alex Hill on 5/27/17.
//
//

internal enum PhotoLoadingState: Int {
    case notLoaded, loading, loaded, loadingFailed
}

internal var PhotoErrorAssociationKey: UInt8 = 0
internal var PhotoProgressAssociationKey: UInt8 = 0
internal var PhotoLoadingStateAssociationKey: UInt8 = 0
internal var PhotoLoadingViewClassAssociationKey: UInt8 = 0

internal extension Photo {
    
    var progress: Progress {
        get {
            return objc_getAssociatedObject(self, &PhotoProgressAssociationKey) as? Progress ?? Progress()
        }
        set(value) {
            objc_setAssociatedObject(self, &PhotoProgressAssociationKey, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var error: Error? {
        get {
            return objc_getAssociatedObject(self, &PhotoErrorAssociationKey) as? Error
        }
        set(value) {
            objc_setAssociatedObject(self, &PhotoErrorAssociationKey, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var loadingState: PhotoLoadingState {
        get {
            return objc_getAssociatedObject(self, &PhotoLoadingStateAssociationKey) as? PhotoLoadingState ?? .notLoaded
        }
        set(value) {
            objc_setAssociatedObject(self, &PhotoLoadingStateAssociationKey, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var loadingViewClass: LoadingViewProtocol.Type? {
        get {
            return objc_getAssociatedObject(self, &PhotoLoadingViewClassAssociationKey) as? LoadingViewProtocol.Type
        }
        set(value) {
            objc_setAssociatedObject(self, &PhotoLoadingViewClassAssociationKey, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
}
