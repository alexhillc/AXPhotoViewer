//
//  ExamplePhoto.swift
//  BAPPhotosViewControllerExample
//
//  Created by Alex Hill on 5/21/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import BAPPhotosViewController

class ExamplePhoto: NSObject, Photo {
    
    init(title: NSAttributedString?, caption: NSAttributedString?, credit: NSAttributedString?, url: URL) {
        self.title = title
        self.caption = caption
        self.credit = credit
        self.url = url
        super.init()
    }
    
    /// The attributed title of the image that will be displayed in the photo's `overlay`.
    var title: NSAttributedString?
    
    /// The attributed caption of the image that will be displayed in the photo's `overlay`.
    var caption: NSAttributedString?
    
    /// The attributed credit of the image that will be displayed in the photo's `overlay`.
    var credit: NSAttributedString?
    
    /// The image data. If this value is present, it will be prioritized over `image`.
    /// Provide animated GIF data to this property.
    var imageData: Data?
    
    /// The image to be displayed. If this value is present, it will be prioritized over `URL`.
    var image: UIImage?
    
    /// The URL of the image.
    var url: URL?

}
