//
//  Photo+Internal.swift
//  Pods
//
//  Created by Alex Hill on 5/27/17.
//
//

enum PhotoLoadingState: Int {
    case notLoaded, loading, loaded, loadingFailed
}

var PhotoErrorAssociationKey: UInt8 = 0
var PhotoProgressAssociationKey: UInt8 = 0
var PhotoLoadingStateAssociationKey: UInt8 = 0

// MARK: - Internal PhotoProtocol extension to be used by the framework.
extension PhotoProtocol {
    
    var progress: CGFloat {
        get {
            return objc_getAssociatedObject(self, &PhotoProgressAssociationKey) as? CGFloat ?? 0
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
    
}
