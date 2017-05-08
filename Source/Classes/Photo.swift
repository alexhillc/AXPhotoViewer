//
//  Photo.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(BAPPhoto) protocol Photo: class {
    
    /// The attributed title of the image that will be displayed in the photo's `overlay`.
    @objc var title: NSAttributedString? { get }
    
    /// The attributed caption of the image that will be displayed in the photo's `overlay`.
    @objc var caption: NSAttributedString? { get }
    
    /// The attributed credit of the image that will be displayed in the photo's `overlay`.
    @objc var credit: NSAttributedString? { get }
    
    /// The URL of the image to be loaded.
    @objc var url: URL { get }
    
    /// The image to be displayed. Expected to be `nil` if the image has not been downloaded yet.
    @objc var image: UIImage? { get }
    
}
