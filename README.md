# AXPhotoViewer [![Build Status](https://travis-ci.org/alexhillc/AXPhotoViewer.svg?branch=master)](https://travis-ci.org/alexhillc/AXPhotoViewer)

<p align="center">
  <img src="http://i.imgur.com/Y3ovA03.gif" alt="Demo GIF #1"/>
  <img src="http://i.imgur.com/CCs0TzM.gif" alt="Demo GIF #2"/>
</p>

AXPhotoViewer is an iOS/tvOS photo viewer that is useful for viewing a very large (or very small!) amount of images and GIFs. This library supports contextual presentation and dismissal, interactive "flick-to-dismiss" behavior, and easily integrates with many third party async image downloading/caching libraries.

### How to use
While AXPhotoViewer has many configurable properties on each of its modules, it is easy to throw down some initialization code and get started:

```swift
let dataSource = AXPhotosDataSource(photos: self.photos)
let photosViewController = PhotosViewController(dataSource: dataSource)
self.present(photosViewController, animated: true)
```

#### Force touch implementation?
It's easy to implement force touch with this library by using `PreviewingPhotosViewController`:

```swift
func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                      viewControllerForLocation location: CGPoint) -> UIViewController? {

    guard let indexPath = self.tableView.indexPathForRow(at: location),
        let cell = self.tableView.cellForRow(at: indexPath),
        let imageView = cell.imageView else {
        return nil
    }

    previewingContext.sourceRect = self.tableView.convert(imageView.frame, from: imageView.superview)

    let dataSource = AXPhotosDataSource(photos: self.photos, initialPhotoIndex: indexPath.row)
    let previewingPhotosViewController = PreviewingPhotosViewController(dataSource: dataSource)

    return previewingPhotosViewController
}

func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                      commit viewControllerToCommit: UIViewController) {

    if let previewingPhotosViewController = viewControllerToCommit as? PreviewingPhotosViewController {
        self.present(PhotosViewController(from: previewingPhotosViewController), animated: false)
    }
}
```

### Objective-C interoperability
This library fully supports interop between Objective-C and Swift codebases. If you run into any issues with this, please open a Github issue or submit a pull request with the suggested changes.

### Installation
Installation can easily be done through Cocoapods:
```ruby
pod install 'AXPhotoViewer'
```
If you prefer not to use Cocoapods, add the contents of the 'Source' directory to your project to get started.

**Note:** If you don't use Cocoapods, you must add `MobileCoreServices.framework`, `QuartzCore.framework`, and `ImageIO.framework` to your project.

### Configuration
There are many configurable properties that can be set before presenting your `AXPhotosViewController`.

For example, on the `AXPhotoDataSource` object, you may set up the data source with an initial page index, as well as being able to control the rate at which the library will download additional photos.

```swift
let photos = [first, second]
let dataSource = AXPhotosDataSource(photos: photos, initialPhotoIndex: 1, prefetchBehavior: .aggressive)
```

On the `AXPagingConfig` object, you may set up the configuration with a different navigation orientation (horizontal vs vertical scrolling between pages), inter-photo spacing (the spacing, in points, between each photo), and/or a custom loading view class that will be instantiated by the library as needed.

```swift
let pagingConfig = AXPagingConfig(navigationOrientation: .horizontal, interPhotoSpacing: 20, loadingViewClass: CustomLoadingView.self)
```

Lastly, but surely not least, is the `AXTransitionInfo` configuration. This can be used to customize all things related to the presentation and dismissal of your `AXPhotosViewController`, including the starting reference view, the ending reference view, the duration of the animations, and a flag to disable/enable interactive dismissals.

```swift
let transitionInfo = AXTransitionInfo(interactiveDismissalEnabled: false, startingView: self.startingImageView) { [weak self] (photo, index) -> UIImageView? in
    // this closure can be used to adjust your UI before returning an `endingImageView`.
    return self?.endingImageView
}
```

### Custom views
It's very simple to add a custom self-sizing view to the view hierarchy of the photo viewer by accessing properties on the `OverlayView`. The `topStackContainer` and `bottomStackContainer` are exactly what they sound like, anchored to either the top or bottom of the overlay. All that is necessary to add your custom view to these containers is the following:

```swift
photosViewController.overlayView.topStackContainer.addSubview(customSubview1)
photosViewController.overlayView.bottomStackContainer.addSubview(customSubview2)
```

These views will be sized and stacked in the order that they are added. It's possible to re-order these subviews to fit your needs.

### Network Integrations
A network integration, in relation to this library, is a class conforming to the `AXNetworkIntegration` protocol. This protocol defines some methods to be used for downloading images, as well as delegating their completions (and errors) to the library. If you wish to create your own module for async downloading/caching of images and gifs, the protocol is fairly lightweight.

Some pre-defined `AXNetworkIntegrations` have already been made as Cocoapod subspecs (SDWebImage, PINRemoteImage, AFNetworking, Kingfisher, Nuke..., as well as a simple network integration using NSURLSession that will serve most people's purposes quite sufficiently). To use these pre-defined subspecs, simply change your `Podfile`:

```ruby
pod install 'AXPhotoViewer/Lite'
pod install 'AXPhotoViewer/SDWebImage'
pod install 'AXPhotoViewer/PINRemoteImage'
pod install 'AXPhotoViewer/AFNetworking'
pod install 'AXPhotoViewer/Kingfisher'
pod install 'AXPhotoViewer/Nuke'
```

To create your own `AXNetworkIntegration`:
```ruby
pod install 'AXPhotoViewer/Core'
```
```swift
let customNetworkIntegration = CustomNetworkIntegration() // instantiate your custom network integration
let dataSource = AXPhotosDataSource(photos: self.photos)
let photosViewController = PhotosViewController(dataSource: dataSource, networkIntegration: customNetworkIntegration)
```

#### Enabling Nuke's support for GIFs
Nuke's support for downloading GIFs is disabled by default. If you want support for GIFs, you have to enabled it.

```swift
ImagePipeline.Configuration.isAnimatedImageDataEnabled = true
```

More details here: [Nuke animated images](https://github.com/kean/Nuke#animated-images)

### Customization
As mentioned earlier, there are many configurable properties on each of the modules of the photo viewer, and you can access those modules through the `AXPhotosViewController`. For instance, you may replace the default loading view, caption view, and/or overlay title view with your own. These views must be self sizing, and conform to the `AXLoadingViewProtocol`, `AXCaptionViewProtocol`, and `AXOverlayTitleViewProtocol` respectively.

```swift
let pagingConfig = AXPagingConfig(loadingViewClass: CustomLoadingView.self) // custom loading view class to be instantiated as necessary
```
```swift
...
photosViewController.overlayView.captionView = CustomCaptionView() // custom caption view
photosViewController.overlayView.titleView = CustomTitleView() // custom title view
```

The `AXPhotosViewController` and its modules are very extensible, so subclassing each is an easy feat to accomplish without breaking other areas of the library.

### Contributions
If you see something you would like changed, I'm open to ideas! Open a Github issue if you see something wrong, or fork the repo and open a pull request with your changes. I'd be happy to look them over!
