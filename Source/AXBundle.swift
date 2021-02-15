//
//  AXBundle.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 3/10/18.
//

import UIKit

struct AXBundle {
    
    static var frameworkBundle: Bundle {
        return Bundle(for: AXPhotosViewController.self)
    }

}
