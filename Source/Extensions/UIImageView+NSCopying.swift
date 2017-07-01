
//
//  UIImageView+NSCopying.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/10/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

extension UIImageView: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let imageView = type(of: self).init()
        imageView.image = self.image
        imageView.transform = self.transform
        imageView.bounds = self.bounds
        imageView.layer.cornerRadius = self.layer.cornerRadius
        imageView.layer.masksToBounds = self.layer.masksToBounds
        imageView.contentMode = self.contentMode
        return imageView
    }
    
}
