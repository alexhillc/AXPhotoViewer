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
import PINRemoteImage

// This class contains some hacked together sample project code that I couldn't be arsed to make less ugly. ¯\_(ツ)_/¯
class TableViewController: UITableViewController, AXPhotosViewControllerDelegate, UIViewControllerPreviewingDelegate {
    
    let ReuseIdentifier = "AXReuseIdentifier"
    
    var previewingContext: UIViewControllerPreviewing?
    
    weak var photosViewController: AXPhotosViewController?
    weak var customView: UILabel?
    
    let photos = [
        AXPhoto(attributedTitle: NSAttributedString(
                string: "Niagara Falls"),
                image: UIImage(named: "niagara-falls"
            )
        ),
        AXPhoto(
            attributedTitle: NSAttributedString(
                string: "The Flash Poster",
                attributes:[
                    .font: UIFont.italicSystemFont(ofSize: 24),
                    .paragraphStyle: {
                        let style = NSMutableParagraphStyle()
                        style.alignment = .right
                        return style
                    }()
                ]
            ),
            attributedDescription: NSAttributedString(
                string: "Season 3",
                attributes:[
                    .paragraphStyle: {
                        let style = NSMutableParagraphStyle()
                        style.alignment = .right
                        return style
                    }()
                ]),
            attributedCredit: NSAttributedString(
                string: "Vignette",
                attributes:[
                    .paragraphStyle: {
                        let style = NSMutableParagraphStyle()
                        style.alignment = .right
                        return style
                    }()
                ]
            ),
            url: URL(string: "https://goo.gl/T4oZudY")),
        AXPhoto(attributedTitle: NSAttributedString(string: "Tall Building"),
              attributedDescription: NSAttributedString(string: "... And subsequently tall image"),
              attributedCredit: NSAttributedString(string: "Wikipedia"),
              image: UIImage(named: "burj-khalifa")),
        AXPhoto(attributedTitle: NSAttributedString(string: "The Flash: Rebirth"),
              attributedDescription: NSAttributedString(string: "Comic Book"),
              attributedCredit: NSAttributedString(string: "DC Comics"),
              url: URL(string: "https://goo.gl/9wgyAo")),
        AXPhoto(attributedTitle: NSAttributedString(string: "The Flash has a cute smile"),
              attributedDescription: nil,
              attributedCredit: NSAttributedString(string: "Giphy"),
              url: URL(string: "https://media.giphy.com/media/IOEcl8A8iLIUo/giphy.gif")),
        AXPhoto(attributedTitle: NSAttributedString(string: "The Flash slinging a rocket"),
              attributedDescription: nil,
              attributedCredit: NSAttributedString(string: "Giphy"),
              url: URL(string: "https://media.giphy.com/media/lXiRDbPcRYfUgxOak/giphy.gif"))
    ]
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft]
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 9.0, *) {
            if self.traitCollection.forceTouchCapability == .available {
                if self.previewingContext == nil {
                    self.previewingContext = self.registerForPreviewing(with: self, sourceView: self.tableView)
                }
            } else if let previewingContext = self.previewingContext {
                self.unregisterForPreviewing(withContext: previewingContext)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseIdentifier)
        self.tableView.estimatedRowHeight = 350
        self.tableView.rowHeight = 350
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier) else { return UITableViewCell() }
        
        // sample project worst practices top kek
        if cell.contentView.viewWithTag(666) == nil {
            let imageView = FLAnimatedImageView()
            imageView.tag = 666
            imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            imageView.layer.cornerRadius = 20
            imageView.layer.masksToBounds = true
            imageView.contentMode = UIView.ContentMode(rawValue: Int(arc4random_uniform(UInt32(13))))!;
            cell.contentView.addSubview(imageView)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let imageView = cell.contentView.viewWithTag(666) as? FLAnimatedImageView else { return }
        
        self.cancelLoad(at: indexPath, for: imageView)
        self.loadContent(at: indexPath, into: imageView)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let imageView = cell?.contentView.viewWithTag(666) as? FLAnimatedImageView
        
        let transitionInfo = AXTransitionInfo(interactiveDismissalEnabled: true, startingView: imageView) { [weak self] (photo, index) -> UIImageView? in
            guard let `self` = self else { return nil }
            
            let indexPath = IndexPath(row: index, section: 0)
            guard let cell = self.tableView.cellForRow(at: indexPath) else { return nil }
            
            // adjusting the reference view attached to our transition info to allow for contextual animation
            return cell.contentView.viewWithTag(666) as? FLAnimatedImageView
        }
        
        let container = UIViewController()
        
        let dataSource = AXPhotosDataSource(photos: self.photos, initialPhotoIndex: indexPath.row)
        let pagingConfig = AXPagingConfig(loadingViewClass: CustomLoadingView.self)
        let photosViewController = AXPhotosViewController(dataSource: dataSource, pagingConfig: pagingConfig, transitionInfo: transitionInfo)
//        photosViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        photosViewController.delegate = self
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let bottomView = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 44)))
        let customView = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 80, height: 20)))
        customView.text = "\(photosViewController.currentPhotoIndex + 1)"
        customView.textColor = .white
        customView.sizeToFit()
        bottomView.items = [
            UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil),
            flex,
            UIBarButtonItem(customView: customView),
            flex,
            UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil),
        ]
        bottomView.backgroundColor = .clear
        bottomView.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        photosViewController.overlayView.bottomStackContainer.insertSubview(bottomView, at: 0) // insert custom
        
        self.customView = customView
        
//        container.addChildViewController(photosViewController)
//        container.view.addSubview(photosViewController.view)
//        photosViewController.didMove(toParentViewController: container)
        
        self.present(photosViewController, animated: true)
        self.photosViewController = photosViewController
    }
    
    // MARK: - AXPhotosViewControllerDelegate
    func photosViewController(_ photosViewController: AXPhotosViewController,
                              willUpdate overlayView: AXOverlayView,
                              for photo: AXPhotoProtocol,
                              at index: Int,
                              totalNumberOfPhotos: Int) {
        
        self.customView?.text = "\(index + 1)"
        self.customView?.sizeToFit()
    }
    
    // MARK: - Loading
    func loadContent(at indexPath: IndexPath, into imageView: FLAnimatedImageView) {
        func onBackgroundThread(_ block: @escaping () -> Void) {
            if Thread.isMainThread {
                DispatchQueue.global().async {
                    block()
                }
            } else {
                block()
            }
        }
        
        func onMainThread(_ block: @escaping () -> Void) {
            if Thread.isMainThread {
                block()
            } else {
                DispatchQueue.main.async {
                    block()
                }
            }
        }
        
        func layoutImageView(with result: Any?) {
            let maxSize: CGFloat = 280
            var imageViewSize: CGSize
            if let animatedImage = result as? FLAnimatedImage {
                imageViewSize = (animatedImage.size.width > animatedImage.size.height) ?
                    CGSize(width: maxSize,height: (maxSize * animatedImage.size.height / animatedImage.size.width)) :
                    CGSize(width: maxSize * animatedImage.size.width / animatedImage.size.height, height: maxSize)
                
                onMainThread {
                    imageView.frame.size = imageViewSize
                    if let superview = imageView.superview {
                        imageView.center = superview.center
                    }
                }
            } else if let image = result as? UIImage {
                imageViewSize = (image.size.width > image.size.height) ?
                    CGSize(width: maxSize, height: (maxSize * image.size.height / image.size.width)) :
                    CGSize(width: maxSize * image.size.width / image.size.height, height: maxSize)
                
                onMainThread {
                    imageView.frame.size = imageViewSize
                    if let superview = imageView.superview {
                        imageView.center = superview.center
                    }
                }
            }
        }
        
        if let imageData = self.photos[indexPath.row].imageData {
            onBackgroundThread {
                let image = FLAnimatedImage(animatedGIFData: imageData)
                onMainThread {
                    imageView.animatedImage = image
                    layoutImageView(with: image)
                }
            }
        } else if let image = self.photos[indexPath.row].image {
            onMainThread {
                imageView.image = image
                layoutImageView(with: image)
            }
        } else if let url = self.photos[indexPath.row].url {
            imageView.pin_setImage(from: url, placeholderImage: nil) { (result) in
                layoutImageView(with: result.alternativeRepresentation ?? result.image)
            }
        }
    }
    
    func cancelLoad(at indexPath: IndexPath, for imageView: FLAnimatedImageView) {
        imageView.pin_cancelImageDownload()
        imageView.animatedImage = nil
        imageView.image = nil
    }
    
    // MARK: - UIViewControllerPreviewingDelegate
    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location),
            let cell = self.tableView.cellForRow(at: indexPath),
            let imageView = cell.contentView.viewWithTag(666) as? FLAnimatedImageView else {
            return nil
        }
        
        previewingContext.sourceRect = self.tableView.convert(imageView.frame, from: imageView.superview)
        
        let dataSource = AXPhotosDataSource(photos: self.photos, initialPhotoIndex: indexPath.row)
        let previewingPhotosViewController = AXPreviewingPhotosViewController(dataSource: dataSource)
        
        return previewingPhotosViewController
    }
    
    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let previewingPhotosViewController = viewControllerToCommit as? AXPreviewingPhotosViewController {
            self.present(AXPhotosViewController(from: previewingPhotosViewController), animated: false)
        }
    }
}
