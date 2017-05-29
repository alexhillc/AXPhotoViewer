//
//  UIImage+GIF.swift
//  Pods
//
//  Created by Alex Hill on 5/21/17.
//
//

public extension UIImage {
    
    func isAnimatedGIF() -> Bool {
        return (self.images != nil)
    }

}
