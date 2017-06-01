//
//  PhotoProtocol.swift
//  Pods
//
//  Created by Alex Hill on 5/7/17.
//
//

@objc(AXPhotoProtocol) public protocol PhotoProtocol: AnyObject, NSObjectProtocol {
    
    /// The attributed title of the image that will be displayed in the photo's `captionView`.
    var attributedTitle: NSAttributedString? { get }
    
    /// The attributed description of the image that will be displayed in the photo's `captionView`.
    var attributedDescription: NSAttributedString? { get }
    
    /// The attributed credit of the image that will be displayed in the photo's `captionView`.
    var attributedCredit: NSAttributedString? { get }
    
    /// The image data. If this value is present, it will be prioritized over `image`.
    /// Provide animated GIF data to this property.
    var imageData: Data? { get set }
    
    /// The image to be displayed. If this value is present, it will be prioritized over `URL`.
    var image: UIImage? { get set }
    
    /// The URL of the image.
    var url: URL? { get }
    
}
