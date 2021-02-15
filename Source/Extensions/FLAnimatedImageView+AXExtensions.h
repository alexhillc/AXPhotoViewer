//
//  FLAnimatedImageView+AXExtensions.h
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/11/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@import FLAnimatedImage;

@interface FLAnimatedImageView (AXExtensions)

/**
 Syncs the sender's frames with the `imageView` passed in.

 @param imageView The `imageView` to inherit from.
 */
- (void)ax_syncFramesWithImageView:(nullable FLAnimatedImageView *)imageView;

@end
