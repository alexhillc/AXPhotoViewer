//
//  AXBundle.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 3/10/18.
//

struct AXBundle {
    
    static var frameworkBundle: Bundle {
        return Bundle(for: AXPhotosViewController.self)
    }

    static var resourcesBundle: Bundle? {
        
        let bundle = AXBundle.frameworkBundle
        guard let path = bundle.path(forResource: "AXPhotoViewerResources", ofType: "bundle") else { return nil }
        
        return Bundle(path: path)
    }
}
