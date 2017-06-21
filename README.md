# AXPhotoViewer
AXPhotoViewer is an iOS photo viewer that is useful for viewing a very large (or very small!) amount of images and GIFs. This library supports contextual presentation and dismissal, interactive "flick-to-dismiss" behavior, and easily integrates with many third party async image downloading/caching libraries.

While AXPhotoViewer has many configurable properties on each of its modules, it is easy to throw down some initialization code and get started:

```swift
let dataSource = PhotosDataSource(photos: self.photos, prefetchBehavior: .regular)
let pagingConfig = PagingConfig(navigationOrientation: .horizontal)
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
or, if you prefer not to use Cocoapods, add the contents of the 'Source' directory to your project to get started.

More info to come.
