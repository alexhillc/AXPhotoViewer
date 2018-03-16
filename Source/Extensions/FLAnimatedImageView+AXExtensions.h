//
//  FLAnimatedImageView+AXExtensions.h
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/11/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

#if TARGET_OS_IOS
@import FLAnimatedImage.FLAnimatedImageView;
#elif TARGET_OS_TV
@import FLAnimatedImage_tvOS.FLAnimatedImageView;
#endif

@interface FLAnimatedImageView (AXExtensions)

/**
 Syncs the sender's frames with the `imageView` passed in.

 @param imageView The `imageView` to inherit from.
 */
- (void)ax_syncFramesWithImageView:(nullable FLAnimatedImageView *)imageView;

@end
