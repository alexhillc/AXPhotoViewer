//
//  ZoomingScrollView.swift
//  Pods
//
//  Created by Alex Hill on 5/21/17.
//
//

import UIKit

@objc(BAPZoomingScrollView) public class ZoomingScrollView: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    fileprivate(set) var zoomView: UIView

    public init(zoomView: UIView) {
        self.zoomView = zoomView
        
        super.init(frame: .zero)
        
        self.zoomView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.zoomView.backgroundColor = UIColor.clear
        self.zoomView.isUserInteractionEnabled = true
        self.addSubview(self.zoomView)
        
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIScrollViewDelegate
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.zoomView
    }
    
    // MARK: - UITapGestureRecognizer
    @objc fileprivate func doubleTapAction(_ sender: UITapGestureRecognizer) {
        if self.zoomScale > 1 {
            self.zoom(to: self.frame, animated: true)
        } else {
            let contentSize = CGSize(width: self.contentSize.width / self.zoomScale,
                                     height: self.contentSize.height / self.zoomScale)
            
            var zoomPoint = sender.location(in: self.zoomView)
            zoomPoint.x = (zoomPoint.x / self.bounds.size.width) * contentSize.width
            zoomPoint.y = (zoomPoint.y / self.bounds.size.height) * contentSize.height
            
            let zoomSize = CGSize(width: self.bounds.size.width / self.maximumZoomScale, height: self.bounds.size.height / self.maximumZoomScale)
            let zoomRect = CGRect(origin: CGPoint(x: zoomPoint.x - zoomSize.width / 2,
                                                  y: zoomPoint.y - zoomSize.height / 2),
                                  size: zoomSize)
            self.zoom(to: zoomRect, animated: true)
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}
