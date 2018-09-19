//
//  AXImageViewTransitionContainer.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/8/18.
//

import UIKit

final class AXImageViewTransitionContainer: UIView {
    
    override var contentMode: UIView.ContentMode {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    let imageView: UIImageView
    
    init(imageView: UIImageView) {
        self.imageView = imageView
        super.init(frame: .zero)
        
        // inherit the imageView's content mode.
        self.contentMode = imageView.contentMode
        imageView.contentMode = .scaleToFill
        
        // inherit the imageView's geometry
        self.frame = imageView.bounds
        
        // inherit the imageView's corner radius
        self.layer.cornerRadius = imageView.layer.cornerRadius
        imageView.layer.cornerRadius = 0
        
        // inherit the imageView's bounds masking
        self.layer.masksToBounds = imageView.layer.masksToBounds;
        imageView.layer.masksToBounds = false
        
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let imageSize = self.imageView.image?.size else {
            return
        }
        
        switch self.contentMode {
        case .scaleToFill:
            self.imageView.bounds = self.bounds.size.rect()
            self.imageView.center = self.bounds.size.center()
        case .scaleAspectFit:
            self.imageView.bounds = self.bounds.aspectFitRect(forSize: imageSize)
            self.imageView.center = self.bounds.size.center()
        case .scaleAspectFill:
            self.imageView.bounds = self.bounds.aspectFillRect(forSize: imageSize)
            self.imageView.center = self.bounds.size.center()
        case .redraw:
            self.imageView.bounds = self.bounds.aspectFillRect(forSize: imageSize)
            self.imageView.center = self.bounds.size.center()
        case .center:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.center()
        case .top:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.centerTop(forSize: imageSize)
        case .bottom:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.centerBottom(forSize: imageSize)
        case .left:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.centerLeft(forSize: imageSize)
        case .right:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.centerRight(forSize: imageSize)
        case .topLeft:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.topLeft(forSize: imageSize)
        case .topRight:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.topRight(forSize: imageSize)
        case .bottomLeft:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.bottomLeft(forSize: imageSize)
        case .bottomRight:
            self.imageView.bounds = imageSize.rect()
            self.imageView.center = self.bounds.size.bottomRight(forSize: imageSize)
        }
    }
    
}
