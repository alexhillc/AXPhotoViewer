//
//  TableViewController.swift
//  AXPhotoViewerExample
//
//  Created by Alex Hill on 6/4/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import AXPhotoViewer
import FLAnimatedImage

// This class contains some hacked together sample project code that I couldn't be arsed to make less ugly. ¯\_(ツ)_/¯
class TableViewController: UITableViewController, PhotosViewControllerDelegate {
    
    let ReuseIdentifier = "AXReuseIdentifier"
    
    var urlSession = URLSession(configuration: .default)
    var content = [Int: Data]()
    
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
        
        // sample project worst practices top kek
        if cell.contentView.viewWithTag(666) == nil {
            let imageView = FLAnimatedImageView()
            imageView.tag = 666
            imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            imageView.layer.cornerRadius = 20
            imageView.layer.masksToBounds = true
            imageView.contentMode = .scaleAspectFit
            cell.contentView.addSubview(imageView)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let imageView = cell.contentView.viewWithTag(666) as? FLAnimatedImageView else {
            return
        }
        
        imageView.image = nil
        imageView.animatedImage = nil
        
        let maxSize = cell.frame.size.height

        self.loadContent(at: indexPath) { (uData) in
            func onMainQueue(_ block: @escaping () -> Void) {
                if Thread.isMainThread {
                    block()
                } else {
                    DispatchQueue.main.async {
                        block()
                    }
                }
            }
            
            var imageViewSize: CGSize
            if let animatedImage = FLAnimatedImage(animatedGIFData: uData) {
                imageViewSize = (animatedImage.size.width > animatedImage.size.height) ?
                    CGSize(width: maxSize,height: (maxSize * animatedImage.size.height / animatedImage.size.width)) :
                    CGSize(width: maxSize * animatedImage.size.width / animatedImage.size.height, height: maxSize)
                
                onMainQueue {
                    imageView.animatedImage = animatedImage
                    imageView.frame.size = imageViewSize
                    imageView.center = cell.contentView.center
                }
                
            } else if let image = UIImage(data: uData) {
                imageViewSize = (image.size.width > image.size.height) ?
                    CGSize(width: maxSize,height: (maxSize * image.size.height / image.size.width)) :
                    CGSize(width: maxSize * image.size.width / image.size.height, height: maxSize)
                
                onMainQueue {
                    imageView.image = image
                    imageView.frame.size = imageViewSize
                    imageView.center = cell.contentView.center
                }
            }
        }
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
    
    // MARK: - Loading
    func loadContent(at indexPath: IndexPath, completion: ((_ data: Data) -> Void)?) {
        if let data = self.content[indexPath.row] {
            completion?(data)
            return
        }
        
        self.urlSession.dataTask(with: self.photos[indexPath.row].url!) { [weak self] (data, response, error) in
            guard let uSelf = self, let uData = data else {
                return
            }
            
            uSelf.content[indexPath.row] = uData
            completion?(uData)
        }.resume()
    }
    
    // MARK: - PhotosViewControllerDelegate
    func photosViewController(_ photosViewController: PhotosViewController, didNavigateTo photo: PhotoProtocol, at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .none, animated: false)
        
        // ideally, _your_ URL cache will be large enough to the point where this isn't necessary 
        // (or, you're using a predefined integration that has a shared cache with your codebase)
        self.loadContent(at: indexPath, completion: nil)
    }
    
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
