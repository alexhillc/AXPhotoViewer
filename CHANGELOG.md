# 1.0.0-beta.15
- **[NEW]** Allow `PhotosViewController` to be initialized without a dataSource - end goal is to allow for a
situation where the content that the dataSource needs is not retrieved yet, but still being able to present
an empty photo viewer

# 1.0.0-beta.14
- **[FIXED]** Transition cancellation duration - now linear
- **[FIXED]** `AXCaptionView` height animation only beginning after caption label text has been changed
- **[FIXED]** Ooverlay content inset when status bar is expanded (in-call, location)
