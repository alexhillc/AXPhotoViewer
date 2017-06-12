//
//  FLAnimatedImageView+AXExtensions.h
//  Pods
//
//  Created by Alex Hill on 6/11/17.
//
//

@import Foundation;
@import FLAnimatedImage;

@interface FLAnimatedImageView (AXExtensions)

/**
 Syncs the sender's frames with the `imageView` passed in.

 @param imageView The `imageView` to inherit from.
 */
- (void)syncFramesWithImageView:(FLAnimatedImageView *)imageView;

@end
