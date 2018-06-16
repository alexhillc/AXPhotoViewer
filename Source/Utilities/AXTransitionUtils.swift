//
//  AXTransitionUtils.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/9/18.
//

import AVFoundation
import UIKit
import QuartzCore

extension CGSize {
    
    func rect() -> CGRect {
        return CGRect(origin: .zero, size: self)
    }
    
    func center() -> CGPoint {
        return CGPoint(x: self.width / 2, y: self.height / 2)
    }
    
    func centerTop(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: self.width / 2, y: size.height / 2)
    }
    
    func centerBottom(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: self.width / 2, y: self.height - size.height / 2)
    }
    
    func centerLeft(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: size.width / 2, y: self.height / 2)
    }
    
    func centerRight(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: self.width - size.width / 2, y: self.height / 2)
    }
    
    func topLeft(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: size.width / 2, y: size.height / 2)
    }
    
    func topRight(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: self.width - size.width / 2, y: size.height / 2)
    }
    
    func bottomLeft(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: size.width / 2, y: self.height - size.height / 2)
    }
    
    func bottomRight(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: self.width - size.width / 2, y: self.height - size.height / 2)
    }
    
}

extension CGRect {
    
    func aspectFitRect(forSize size: CGSize) -> CGRect {
        return AVMakeRect(aspectRatio: size, insideRect: self)
    }
    
    func aspectFillRect(forSize size: CGSize) -> CGRect {
        let sizeRatio = size.width / size.height
        let selfSizeRatio = self.width / self.height
        if sizeRatio > selfSizeRatio {
            return CGRect(x: 0, y: 0, width: floor(self.height * sizeRatio), height: self.height)
        } else {
            return CGRect(x: 0, y: 0, width: self.width, height: floor(self.width / sizeRatio))
        }
    }
    
}
