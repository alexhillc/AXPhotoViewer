//
//  ZoomingImageView.swift
//  Pods
//
//  Created by Alex Hill on 5/21/17.
//
//

import UIKit
import FLAnimatedImage

@objc(BAPZoomingImageView) public class ZoomingImageView: UIScrollView, UIScrollViewDelegate {
    
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
    
    public override var frame: CGRect {
        didSet(value) {
            self.updateZoomScale()
        }
    }
    
    private(set) var doubleTapGestureRecognizer = UITapGestureRecognizer()
    fileprivate var imageView = FLAnimatedImageView()

    public init() {
        super.init(frame: .zero)
        
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        self.doubleTapGestureRecognizer.addTarget(self, action: #selector(doubleTapAction(_:)))
        self.addGestureRecognizer(self.doubleTapGestureRecognizer)
        
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.isUserInteractionEnabled = true
        self.addSubview(self.imageView)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateImageView(image: UIImage?, animatedImage: FLAnimatedImage?) {
        self.imageView.transform = .identity
        self.imageView.animatedImage = nil
        self.imageView.image = nil
        
        var imageSize: CGSize = .zero
        
        if let image = image {
            self.imageView.image = image
            imageSize = image.size
        } else if let animatedImage = animatedImage {
            self.imageView.animatedImage = animatedImage
            imageSize = animatedImage.size
        }
        
        self.imageView.frame = CGRect(origin: .zero, size: imageSize)
        self.contentSize = imageSize
        
        self.updateZoomScale()
    }
    
    // MARK: - UIScrollViewDelegate
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.panGestureRecognizer.isEnabled = true
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ?
            (scrollView.bounds.size.width - scrollView.contentSize.width) / 2 : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) / 2 : 0
        self.imageView.center = CGPoint(x: offsetX + (scrollView.contentSize.width / 2), y: offsetY + (scrollView.contentSize.height / 2))
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard abs(scale - self.minimumZoomScale) <= CGFloat.ulpOfOne else {
            return
        }
        
        self.panGestureRecognizer.isEnabled = false
    }
    
    // MARK: - Zoom scale
    fileprivate func updateZoomScale() {
        guard let imageSize = self.imageView.image?.size ?? self.imageView.animatedImage?.size else {
            return
        }
        
        let scaleWidth = self.bounds.size.width / imageSize.width
        let scaleHeight = self.bounds.size.height / imageSize.height
        self.minimumZoomScale = min(scaleWidth, scaleHeight)
        self.maximumZoomScale = max(self.minimumZoomScale, self.maximumZoomScale)
        
        self.zoomScale = self.minimumZoomScale
        
        self.panGestureRecognizer.isEnabled = false
    }
    
    // MARK: - UITapGestureRecognizer
    @objc fileprivate func doubleTapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.imageView)
        
        var zoomScale = self.maximumZoomScale
        if self.zoomScale >= self.maximumZoomScale || abs(self.zoomScale - self.maximumZoomScale) <= CGFloat.ulpOfOne {
            zoomScale = self.minimumZoomScale
        }
        
        let width = self.bounds.size.width / zoomScale
        let height = self.bounds.size.height / zoomScale
        let originX = point.x - (width / 2)
        let originY = point.y - (height / 2)
        
        let zoomRect = CGRect(x: originX, y: originY, width: width, height: height)
        self.zoom(to: zoomRect, animated: true)
    }

}
