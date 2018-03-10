
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
        imageView.highlightedImage = self.highlightedImage
        imageView.animationImages = self.animationImages
        imageView.highlightedAnimationImages = self.highlightedAnimationImages
        imageView.animationDuration = self.animationDuration
        imageView.animationRepeatCount = self.animationRepeatCount
        imageView.isUserInteractionEnabled = self.isUserInteractionEnabled
        imageView.isHighlighted = self.isHighlighted
        imageView.tintColor = self.tintColor
        imageView.transform = self.transform
        imageView.bounds = self.bounds
        imageView.layer.cornerRadius = self.layer.cornerRadius
        imageView.layer.masksToBounds = self.layer.masksToBounds
        imageView.contentMode = self.contentMode
        return imageView
    }
    
}
