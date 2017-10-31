# 1.3.5
- **[FIXED]** `OverlayView` insets changing on PhotosVC dismissal
- **[FIXED]** `OverlayView` insets could potentially be wrong if a layout was occurring at the same time as a interface show/hide
- **[FIXED]** `LoadingView` could potentially be sized incorrectly on iPhone X
- **[FIXED]** Bad GIF performance

# 1.3.4
- **[FIXED]** `OverlayView` insets changing while interface was animating out (iOS 11)

# 1.3.3
- **[FIXED]** `LoadingView` custom loading indicator improperly sized

# 1.3.2
- **[FIXED]** `LoadingView` retry attributes are the same on iOS 10 & prior
- **[FIXED]** Stackable container will size itself to zero height if there are no
subviews
- **[FIXED]** Updating `OverlayView` title text attributes will update the title
immediately

# 1.3.1
- **[FIXED]** `OverlayView` bar button items were not spaced correctly by default
- **[FIXED]** `StackableViewContainer` was not playing well with animations due to an earlier work aroudn that was made for CaptionView animations, but that is now fixed; as a result, subviews are now laid out at the time of their container's layout

# 1.3.0
- iOS 11 support, Swift 4 migration & support
- iOS 8 support
- **[NEW]** Introduce `StackableViewContainer`, a useful class that will stack self-sizing views on an anchor point. This is used to add custom views anchored at the top and bottom of the OverlayView. OverlayView.topStackContainer, OverlayView.bottomStackContainer can be used to display custom views (button bars, any extra self-sizing views) to the user without a hacky subclass.
- **[NEW]** Adopt iOS 11 `safeAreaInsets` for iPhone X support.
- **[REMOVED]** `CaptionViewDelegate`
- **[FIXED]** `PhotosViewController` initialization would not allow for `OverlayView` manipulation until the view was loaded.

# 1.2.10
- **[FIXED]** `AXLoadingView` subclass would fetch the incorrect asset bundle when searching for default error assets
- **[NEW]** `AXPhotosViewController` now supports being embedded in a fullscreen container and upholding its responsibility as a `UIViewControllerTransitioningDelegate`
- **[FIXED]** #12 (https://github.com/alexhillc/AXPhotoViewer/issues/12), an issue related to lifecycle methods not behaving as expected

# 1.2.9
- Adds `.swift-version`
# 1.2.8
- **[NEW]** `AXLoadingView` extensibility, including text customization and image customization for error views
- **[NEW]** `AXLoadingView` call-to-action retry button
- **[NEW]** `AXLoadingView` default loading error image
- **[FIXED]** `TransitionInfo` endingView resolution could be non-nil after returning nil from the resolution block

# 1.2.7
- **[NEW]** Exposes `currentPhotoIndex` and `currentPhotoViewController` on the `PhotosViewController` (contrib: @justindhill)

# 1.2.6
- Identical to v1.2.5, contains a documentation fix.

# 1.2.5
- **[NEW]** Subclassability of PhotosViewControllerDelegate methods (contrib: @justindhill)

# 1.2.4
- **[NEW]** Animation flag for CaptionView - `PhotosViewController.overlayView.animateCaptionViewChanges`

# 1.2.3
- **[FIXED]** public -> open for overridable variables
- **[CHANGED]** Initialize `PhotosViewController` from `PreviewingPhotosViewController` with `PhotosViewController(from:)`

# 1.2.2
- **[REMOVED]** Coder initializers

# 1.2.1
- **[FIXED]** Build error that was causing AXPhotoViewer/Core to fail spec lint

# 1.2.0
- **[NEW]** More natural flick-to-dismiss behavior, enabling dismissals from strictly swipe velocity as well as dismissal percentage
- **[NEW]** `PreviewingPhotosViewController`: a view controller designed to display an imageView via 3d-touch, see the README for usage details
- **[FIXED]** Missing convenience inits in Obj-C land

# 1.1.1
- **[FIXED]** Retain cycle in `SimpleNetworkIntegration` - [Issue #4](https://github.com/alexhillc/AXPhotoViewer/issues/4)

# 1.1.0
- **[NEW]** Supports presenting with any `modalPresentationStyle` (previously only `UIModalPresentationStyleFullScreen`) - [Issue #3](https://github.com/alexhillc/AXPhotoViewer/issues/3)

# 1.0.0
- **[CHANGED]** Presentation animation style - no longer oscillates, faster

# 1.0.0-beta.17
- **[NEW]** Delegation methods: `-photosViewController:willUpdateOverlayView:forPhoto:atIndex:totalNumberOfPhotos:` and `-photosViewController:maximumZoomScaleForPhoto:minimumZoomScale:imageSize:`
- **[FIXED]** Interactive dismissal without an image will now respond appropriately when an image loads in.

# 1.0.0-beta.16
- **[CHANGED]** Previously, the `PhotosViewController` would only release images/GIF data contained in photos if prompted by `-didReceiveMemoryWarning`.
                Now, the `PhotosViewController` will release photos as they transition out of scope of the currently viewed photos. This will
                help immensely with the memory management of large photo galleries

# 1.0.0-beta.15
- **[NEW]** Allow `PhotosViewController` to be initialized without a dataSource - end goal is to allow for a
            situation where the content that the dataSource needs is not retrieved yet, but still being able to present
            an empty photo viewer

# 1.0.0-beta.14
- **[FIXED]** Transition cancellation duration - now linear
- **[FIXED]** `AXCaptionView` height animation only beginning after caption label text has been changed
- **[FIXED]** Overlay content inset when status bar is expanded (in-call, location)
