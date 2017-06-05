//
//  ViewController.swift
//  AXPhotoViewerExample
//
//  Created by Alex Hill on 6/4/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import AXPhotoViewer

class ViewController: UIViewController {
    
    var urlSession = URLSession(configuration: .default)
    var imageView = UIImageView()
    
    let photos = [
        Photo(attributedTitle: NSAttributedString(string: "The Flash Poster"),
              attributedDescription: NSAttributedString(string: "Season 3"),
              attributedCredit: NSAttributedString(string: "Vignette"),
              url: URL(string: "https://goo.gl/T4oZdY")),
        Photo(attributedTitle: NSAttributedString(string: "The Flash and Savitar"),
              attributedDescription: NSAttributedString(string: "Season 3"),
              attributedCredit: NSAttributedString(string: "Screen Rant"),
              url: URL(string: "https://goo.gl/pYeJ4H")),
        Photo(attributedTitle: NSAttributedString(string: "The Flash: Rebirth"),
              attributedDescription: NSAttributedString(string: "Comic Book"),
              attributedCredit: NSAttributedString(string: "DC Comics"),
              url: URL(string: "https://goo.gl/9wgyAo")),
        Photo(attributedTitle: NSAttributedString(string: "The Flash has a cute smile"),
              attributedDescription: nil,
              attributedCredit: NSAttributedString(string: "Giphy"),
              url: URL(string: "https://media.giphy.com/media/IOEcl8A8iLIUo/giphy.gif"))
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapAction(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.imageView.addGestureRecognizer(tapGestureRecognizer)
        self.imageView.isUserInteractionEnabled = true
        self.view.addSubview(self.imageView)
        
        self.configureImageView()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let image = self.imageView.image {
            let maxSize: CGFloat = 160
            let imageViewSize = (image.size.width > image.size.height) ? CGSize(width: maxSize,
                                                                                height: (maxSize * image.size.height / image.size.width)) :
                                                                         CGSize(width: maxSize * image.size.width / image.size.height,
                                                                                height: maxSize)
            self.imageView.frame.size = imageViewSize
            self.imageView.center = self.view.center
        }

    }
    
    func configureImageView() {
        guard let url = self.photos.first?.url else {
            return
        }
        
        self.urlSession.dataTask(with: url) { [weak self] (data, response, error) in
            guard let uData = data, let image = UIImage(data: uData) else {
                return
            }
            
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.view.setNeedsLayout()
            }
        }.resume()
    }
    
    func imageTapAction(_ sender: UITapGestureRecognizer) {
        let dataSource = PhotosDataSource(photos: self.photos, prefetchBehavior: .regular)
        let pagingConfig = PagingConfig(navigationOrientation: .horizontal)
        let photosViewController = PhotosViewController(dataSource: dataSource, pagingConfig: pagingConfig)
        self.present(photosViewController, animated: true, completion: nil)
    }

}
