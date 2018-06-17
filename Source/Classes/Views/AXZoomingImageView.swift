//
//  ZoomingImageView.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/21/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit

#if os(iOS)
import FLAnimatedImage
#elseif os(tvOS)
import FLAnimatedImage_tvOS
#endif

fileprivate let ZoomScaleEpsilon: CGFloat = 0.01

class AXZoomingImageView: UIScrollView, UIScrollViewDelegate {
    
    #if os(iOS)
    /// iOS-only tap gesture recognizer for zooming.
    fileprivate(set) var doubleTapGestureRecognizer = UITapGestureRecognizer()
    #endif
    
    weak var zoomScaleDelegate: AXZoomingImageViewDelegate?
    
    var image: UIImage? {
        set(value) {
            self.updateImageView(image: value, animatedImage: nil)
        }
        get {
            return self.imageView.image
        }
    }
    
    var animatedImage: FLAnimatedImage? {
        set(value) {
            self.updateImageView(image: nil, animatedImage: value)
        }
        get {
            return self.imageView.animatedImage
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.updateZoomScale()
        }
    }
    
    fileprivate(set) var imageView = FLAnimatedImageView()
    
    fileprivate var needsUpdateImageView = false

    init() {
        super.init(frame: .zero)
        
        #if os(iOS)
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        self.doubleTapGestureRecognizer.addTarget(self, action: #selector(doubleTapAction(_:)))
        self.doubleTapGestureRecognizer.isEnabled = false
        self.addGestureRecognizer(self.doubleTapGestureRecognizer)
        #endif
        
        self.imageView.layer.masksToBounds = true
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.imageView)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.isScrollEnabled = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self
        
        if #available(iOS 11.0, tvOS 11.0, *) {
            self.contentInsetAdjustmentBehavior = .never
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateImageView(image: UIImage?, animatedImage: FLAnimatedImage?) {
        self.imageView.transform = .identity
        var imageSize: CGSize = .zero
        
        if let animatedImage = animatedImage {
            if self.imageView.animatedImage != animatedImage {
                self.imageView.animatedImage = animatedImage
            }
            imageSize = animatedImage.size
        } else if let image = image {
            if self.imageView.image != image {
                self.imageView.image = image
            }
            imageSize = image.size
        } else {
            self.imageView.animatedImage = nil
            self.imageView.image = nil
        }
        
        self.imageView.frame = CGRect(origin: .zero, size: imageSize)
        self.contentSize = imageSize
        self.updateZoomScale()
        
        #if os(iOS)
        self.doubleTapGestureRecognizer.isEnabled = (image != nil || animatedImage != nil)
        #endif
        
        self.needsUpdateImageView = false
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        
        if subview === self.imageView {
            self.needsUpdateImageView = true
        }
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        if subview === self.imageView && self.needsUpdateImageView {
            self.updateImageView(image: self.imageView.image, animatedImage: self.imageView.animatedImage)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.isScrollEnabled = true
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ?
            (scrollView.bounds.size.width - scrollView.contentSize.width) / 2 : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) / 2 : 0
        self.imageView.center = CGPoint(x: offsetX + (scrollView.contentSize.width / 2), y: offsetY + (scrollView.contentSize.height / 2))
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard abs(scale - self.minimumZoomScale) <= ZoomScaleEpsilon else {
            return
        }
        
        scrollView.isScrollEnabled = false
    }
    
    // MARK: - Zoom scale
    fileprivate func updateZoomScale() {
        let imageSize = self.imageView.image?.size ?? self.imageView.animatedImage?.size ?? CGSize(width: 1, height: 1)
        
        let scaleWidth = self.bounds.size.width / imageSize.width
        let scaleHeight = self.bounds.size.height / imageSize.height
        self.minimumZoomScale = min(scaleWidth, scaleHeight)
        
        let delegatedMaxZoomScale = self.zoomScaleDelegate?.zoomingImageView(self, maximumZoomScaleFor: imageSize)
        if let maximumZoomScale = delegatedMaxZoomScale, (maximumZoomScale - self.minimumZoomScale) >= 0 {
            self.maximumZoomScale = maximumZoomScale
        } else {
            self.maximumZoomScale = self.minimumZoomScale * 3.5
        }
        
        // if the zoom scale is the same, change it to force the UIScrollView to
        // recompute the scroll view's content frame
        if abs(self.zoomScale - self.minimumZoomScale) <= .ulpOfOne {
            self.zoomScale = self.minimumZoomScale + 0.1
        }
        self.zoomScale = self.minimumZoomScale
        
        self.isScrollEnabled = false
    }
    
    #if os(iOS)
    // MARK: - UITapGestureRecognizer
    @objc fileprivate func doubleTapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.imageView)
        
        var zoomScale = self.maximumZoomScale
        if self.zoomScale >= self.maximumZoomScale || abs(self.zoomScale - self.maximumZoomScale) <= ZoomScaleEpsilon {
            zoomScale = self.minimumZoomScale
        }
        
        if abs(self.zoomScale - zoomScale) <= .ulpOfOne {
            return
        }
        
        let width = self.bounds.size.width / zoomScale
        let height = self.bounds.size.height / zoomScale
        let originX = point.x - (width / 2)
        let originY = point.y - (height / 2)
        
        let zoomRect = CGRect(x: originX, y: originY, width: width, height: height)
        self.zoom(to: zoomRect, animated: true)
    }
    #endif

}

protocol AXZoomingImageViewDelegate: class {
    func zoomingImageView(_ zoomingImageView: AXZoomingImageView, maximumZoomScaleFor imageSize: CGSize) -> CGFloat
}
