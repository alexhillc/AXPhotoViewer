# 1.7.1
- [**NEW**] Better RTL support on device locales that support RTL (further support will require a refactor using AutoLayout)
- [**FIXED**] KingfisherIntegration was out of date #55

# 1.7.0
- Requires Swift 5.0

# 1.6.1
- [**FIXED**] When captionView layout occurred more than once while animation was occurring, new captions would be applied mid animation

# 1.6.0
- Requires Swift 4.2
- [**FIXED**] Navbar would behave erratically during dismissal if changing the bar button items to anything other than the default
- [**FIXED**] Custom font size would be overwritten by AXCaptionView
- [**FIXED**] NSParagraphStyle alignment would have no effect on caption labels

# 1.5.0
- Requires Swift 4.1
- [**NEW**] Support for new network integration - Nuke. Required iOS/tvOS 9.0 or higher.
- [**NEW**] Support for UIContentMode on reference image views during transitions. The transition animator will adopt the content mode of the startingView and endingView.
- [**NEW**] Support for spring damping ratio in AXTransitionInfo. Control the springy-ness of your transitions by adjusting this value!
- [**NEW**] Supply a custom fade backdrop view if desired. This is defined on the AXTransitionInfo object and will be used during presentation/dismissal transitions. (#36 - thanks @ashitikov!)
- [**FIXED**] Safe area insets being automatically applied to the scrollView during image zoom.
- [**FIXED**] Network integrations will now always return on a background thread. This was a problem for synchronous cache fetches (memory) that were made on the main thread.

# 1.4.3
- [**NEW**] Delegate method: `photosViewController(_:overlayView:visibilityWillChange:)` in order to coordinate overlayView visiblity changes with other animations

# 1.4.2
- Revert to Swift 4.0

# 1.4.1
- Small changes to insets in AXCaptionView on tvOS
- Removes invalid initializer on AXTransitionInfo on tvOS

# 1.4.0
- **[NEW]** tvOS Support has been added
- **[NEW]** Swift 4.1 usage requires **Xcode 9.3**
- **[NEW]** All classes are now namespaced with 'AX' in order to be more subclass-friendly
- **[NEW]** Delegate methods: `photosViewControllerWillDismiss:` and `photosViewControllerDidDismiss:`, which are called for both interactive and non-interactive dismissals [#29](https://github.com/alexhillc/AXPhotoViewer/issues/29)
- **[NEW]** `navigateToPhotoIndex(_:animated:)` to allow developers to navigate between photos programmatically
- **[FIXED]** Localization is now much easier for the `internalTitle` property [#31](https://github.com/alexhillc/AXPhotoViewer/issues/31)
- **[FIXED]** Example project crashes when loading local assets [#25](https://github.com/alexhillc/AXPhotoViewer/issues/25)
- **[CHANGED]** The library now depends on Cocoapods a lot less, opening up the possibility for Carthage support

# 1.3.6
- **[FIXED]** 'CaptionView' sometimes improperly sizing its labels

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
