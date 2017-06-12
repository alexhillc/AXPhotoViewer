//
//  ViewController.swift
//  AXPhotoViewerExample
//
//  Created by Alex Hill on 6/4/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import AXPhotoViewer
import SDWebImage
import FLAnimatedImage

// This class contains some hacked together sample project code that I couldn't be arsed to make less ugly. ¯\_(ツ)_/¯
class ViewController: UITableViewController, PhotosViewControllerDelegate {
    
    let ReuseIdentifier = "AXReuseIdentifier"
    
    var urlSession = URLSession(configuration: .default)
    var imageViews = [FLAnimatedImageView]()
    
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
              url: URL(string: "https://media.giphy.com/media/IOEcl8A8iLIUo/giphy.gif")),
        Photo(attributedTitle: NSAttributedString(string: "The Flash slinging a rocket"),
              attributedDescription: nil,
              attributedCredit: NSAttributedString(string: "Giphy"),
              url: URL(string: "https://media.giphy.com/media/lXiRDbPcRYfUgxOak/giphy.gif"))
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        self.tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 30, right: 0)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseIdentifier)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.scrollIndicatorInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height,
                                                            left: 0,
                                                            bottom: 0,
                                                            right: 0)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier) else {
            return UITableViewCell()
        }
        
        // sample project lulz
        if cell.contentView.viewWithTag(666) == nil {
            let imageView = FLAnimatedImageView()
            imageView.tag = 666
            imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            imageView.layer.cornerRadius = 20
            imageView.layer.masksToBounds = true
            imageView.contentMode = .scaleAspectFit
            cell.contentView.addSubview(imageView)
        }
        
        guard let imageView = cell.contentView.viewWithTag(666) as? FLAnimatedImageView else {
            return UITableViewCell()
        }
        
        imageView.sd_setImage(with: self.photos[indexPath.row].url, completed: { (image, error, cacheType, url) in
            guard let uImage = image else {
                return
            }
                        
            let maxSize: CGFloat = cell.frame.size.height
            let imageViewSize = (uImage.size.width > uImage.size.height) ? CGSize(width: maxSize,
                                                                                height: (maxSize * uImage.size.height / uImage.size.width)) :
                                                                                        CGSize(width: maxSize * uImage.size.width / uImage.size.height,
                                                                                               height: maxSize)
            imageView.frame.size = imageViewSize
            imageView.center = cell.contentView.center
        })
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataSource = PhotosDataSource(photos: self.photos, initialPhotoIndex: indexPath.row, prefetchBehavior: .regular)
        let pagingConfig = PagingConfig(navigationOrientation: .horizontal)
        let photosViewController = PhotosViewController(dataSource: dataSource, pagingConfig: pagingConfig)
        photosViewController.delegate = self
        self.present(photosViewController, animated: true, completion: nil)
    }
    
    // MARK: - PhotosViewControllerDelegate
    func photosViewController(_ photosViewController: PhotosViewController, transitionInfoForDismissalPhoto photo: PhotoProtocol, at index: Int) -> TransitionInfo? {
        let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0))
        guard let imageView = cell?.contentView.viewWithTag(666) as? FLAnimatedImageView else {
            return nil
        }
        
        return TransitionInfo(referenceView: imageView)
    }
    
    func photosViewController(_ photosViewController: PhotosViewController, transitionInfoForPresentationPhoto photo: PhotoProtocol, at index: Int) -> TransitionInfo? {
        let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0))
        guard let imageView = cell?.contentView.viewWithTag(666) as? FLAnimatedImageView else {
            return nil
        }
        
        return TransitionInfo(referenceView: imageView)
    }

}
