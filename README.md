# AXPhotoViewer

[![Build Status](https://travis-ci.org/alexhillc/AXPhotoViewer.svg?branch=master)](https://travis-ci.org/alexhillc/AXPhotoViewer)

<p align="center">
  <img src="http://i.imgur.com/Y3ovA03.gif" alt="Demo GIF #1"/>
  <img src="http://i.imgur.com/CCs0TzM.gif" alt="Demo GIF #2"/>
</p>

AXPhotoViewer is an iOS photo viewer that is useful for viewing a very large (or very small!) amount of images and GIFs. This library supports contextual presentation and dismissal, interactive "flick-to-dismiss" behavior, and easily integrates with many third party async image downloading/caching libraries.

### How to use
While AXPhotoViewer has many configurable properties on each of its modules, it is easy to throw down some initialization code and get started:

```swift
let dataSource = PhotosDataSource(photos: self.photos)
let pagingConfig = PagingConfig()
let transitionInfo = TransitionInfo(startingView: self.startingImageView) { [weak self] (photo, index) -> UIImageView? in
    return self?.endingImageView
}

let photosViewController = PhotosViewController(dataSource: dataSource, pagingConfig: pagingConfig, transitionInfo: transitionInfo)
self.present(photosViewController, animated: true, completion: nil)
```

### Objective-C interoperability
This library fully supports interop between Objective-C and Swift codebases. If you run into any issues with this, please open a Github issue or submit a pull request with the suggested changes.

### Installation
Installation can easily be done through Cocoapods:
```ruby
pod install 'AXPhotoViewer', '~> 1.0.0-beta.5'
```
If you prefer not to use Cocoapods, add the contents of the 'Source' directory to your project to get started.

**Note:** If you don't use Cocoapods, you must add `MobileCoreServices.framework` and `ImageIO.framework` to your project.

### Configuration
There are many configurable properties that can be set before presenting your `AXPhotosViewController`. 

For example, in the `AXPhotoDataSource`, you may set up the data source with an initial page index, as well as being able to control the rate at which the library will download additional photos.

```swift
let photos = [photoFirst, photoSecond]
let initialPhotoIndex = 1
let dataSource = PhotosDataSource(photos: photos, initialPhotoIndex: initialPhotoIndex, prefetchBehavior: .aggressive)
```

In `AXPagingConfig`, you may set up the configuration with a different navigation orientation (horizontal vs vertical scrolling between pages), inter-photo spacing (the spacing, in points, between each photo), and as mentioned earlier, a custom loading view class that will be instantiated rather than the default `AXLoadingView`.

```swift
let pagingConfig = PagingConfig(navigationOrientation: .horizontal, interPhotoSpacing: 20, loadingViewClass: CustomLoadingView.self)
```

Lastly, but surely not least, is the `AXTransitionInfo` configuration. This can be used to customize all things related to the presentation and dismissal of your `AXPhotosViewController`, including the starting reference view, the ending reference view, the duration of the animations, and a flag to disable/enable interactive dismissals.

```swift
let transitionInfo = TransitionInfo(interactiveDismissalEnabled: false, startingView: self.startingImageView) { [weak self] (photo, index) -> UIImageView? in
    // this closure can be used to adjust your UI before returning an `endingImageView`.
    return self?.endingImageView
}
```

### Network Integrations
A network integration, in relation to this library, is a class conforming to the `AXNetworkIntegration` protocol. This protocol defines some methods to be used for downloading images, as well as delegating their completions (and errors!) to the library. If you wish to create your own module for async downloading/caching of images and gifs, the protocol is fairly lightweight.

Some pre-defined `AXNetworkIntegrations` have already been made as Cocoapod subspecs (SDWebImage, PINRemoteImage, AFNetworking..., as well as a simple network integration using NSURLSession that will serve most people's purposes quite sufficiently). To use these pre-defined subspecs, simply change your `Podfile`:

```ruby
pod install 'AXPhotoViewer/Lite', '~> 1.0.0-beta.5'
pod install 'AXPhotoViewer/SDWebImage', '~> 1.0.0-beta.5'
pod install 'AXPhotoViewer/PINRemoteImage', '~> 1.0.0-beta.5'
pod install 'AXPhotoViewer/AFNetworking', '~> 1.0.0-beta.5'
```

To create your own `AXNetworkIntegration`:
```ruby
pod install 'AXPhotoViewer/Core', '~> 1.0.0-beta.5'
```
```swift
let dataSource = ...
let pagingConfig = ...
let transitionInfo = ...
let customNetworkIntegration = CustomNetworkIntegration() // instantiate your custom network integration
let photosViewController = PhotosViewController(dataSource: dataSource, pagingConfig: pagingConfig, transitionInfo: transitionInfo, networkIntegration: customNetworkIntegration)
```

### Customization
As mentioned earlier in the `README.md`, there are many configurable properties on each of the modules of the photo viewer, and you can access those modules through the `AXPhotosViewController`. For instance, you may replace the default loading view, caption view, and/or overlay title view with your own. These views must be self sizing, and conform to the `AXLoadingViewProtocol`, `AXCaptionViewProtocol`, and `AXOverlayTitleView` protocol respectively.

```swift
let pagingConfig = PagingConfig(loadingViewClass: CustomLoadingView.self) // custom loading view class to be instantiated as necessary
```
```swift
...
photosViewController.overlayView.captionView = CustomCaptionView() // custom caption view
photosViewController.overlayView.titleView = CustomTitleView() // custom title view
```

The `AXPhotosViewController` and its modules are very extensible, so subclassing each is an easy feat to accomplish without breaking other areas of the library.

### Contributions
If you see something you would like changed, I'm open to ideas! Open a Github issue if you see something wrong, or fork the repo and open a pull request with your changes. I'd be happy to look them over!
