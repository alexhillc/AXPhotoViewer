//
//  Data+GIF.swift
//  Pods
//
//  Created by Alex Hill on 6/11/17.
//
//

import ImageIO
import MobileCoreServices

extension Data {

    func containsGIF() -> Bool {
        let sourceData = self as CFData
        
        let options: [String: Any] = [kCGImageSourceShouldCache as String: false]
        guard let source = CGImageSourceCreateWithData(sourceData, options as CFDictionary?),
            let sourceContainerType = CGImageSourceGetType(source) else {
            return false
        }
        
        return UTTypeConformsTo(sourceContainerType, kUTTypeGIF)
    }

}
