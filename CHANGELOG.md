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
