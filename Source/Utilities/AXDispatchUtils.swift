//
//  AXDispatchUtils.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/16/18.
//

import Foundation

struct AXDispatchUtils {

    static func executeInBackground(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            DispatchQueue.global().async(execute: block)
        } else {
            block()
        }
    }
    
}
