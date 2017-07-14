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
