//
//  AXPhoto+Internal.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/27/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

#if os(iOS)
import FLAnimatedImage.FLAnimatedImage
#elseif os(tvOS)
import FLAnimatedImage_tvOS.FLAnimatedImage
#endif

enum AXPhotoLoadingState {
    case notLoaded, loading, loaded, loadingCancelled, loadingFailed
}

fileprivate struct AssociationKeys {
    static var error: UInt8 = 0
    static var progress: UInt8 = 0
    static var loadingState: UInt8 = 0
    static var animatedImage: UInt8 = 0
}

// MARK: - Internal AXPhotoProtocol extension to be used by the framework.
extension AXPhotoProtocol {
    
    var ax_progress: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociationKeys.progress) as? CGFloat ?? 0
        }
        set(value) {
            objc_setAssociatedObject(self, &AssociationKeys.progress, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var ax_error: Error? {
        get {
            return objc_getAssociatedObject(self, &AssociationKeys.error) as? Error
        }
        set(value) {
            objc_setAssociatedObject(self, &AssociationKeys.error, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var ax_loadingState: AXPhotoLoadingState {
        get {
            return objc_getAssociatedObject(self, &AssociationKeys.loadingState) as? AXPhotoLoadingState ?? .notLoaded
        }
        set(value) {
            objc_setAssociatedObject(self, &AssociationKeys.loadingState, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var ax_animatedImage: FLAnimatedImage? {
        get {
            return objc_getAssociatedObject(self, &AssociationKeys.animatedImage) as? FLAnimatedImage
        }
        set(value) {
            objc_setAssociatedObject(self, &AssociationKeys.animatedImage, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var ax_isReducible: Bool {
        get {
            return self.url != nil
        }
    }
    
}
