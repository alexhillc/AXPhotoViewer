//
//  Photo.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(BAPPhoto) public protocol Photo: AnyObject, NSObjectProtocol {
    
    /// The attributed title of the image that will be displayed in the photo's `overlay`.
    var title: NSAttributedString? { get }
    
    /// The attributed caption of the image that will be displayed in the photo's `overlay`.
    var caption: NSAttributedString? { get }
    
    /// The attributed credit of the image that will be displayed in the photo's `overlay`.
    var credit: NSAttributedString? { get }
    
    /// The image data. If this value is present, it will be prioritized over `image`.
    /// Provide animated GIF data to this property.
    var imageData: Data? { get set }
    
    /// The image to be displayed. If this value is present, it will be prioritized over `URL`.
    var image: UIImage? { get set }
    
    /// The URL of the image.
    var url: URL? { get }
    
}
