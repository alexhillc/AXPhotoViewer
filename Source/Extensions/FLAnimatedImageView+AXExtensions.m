//
//  FLAnimatedImageView+AXExtensions.m
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/11/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@import FLAnimatedImage;

#import "FLAnimatedImageView+AXExtensions.h"
#import <AXPhotoViewer/AXPhotoViewer-Swift.h>

@interface FLAnimatedImageView ()

/**
 Unfortunately, FLAnimatedImageView does not allow for setting the current frame index, however, it should work just fine
 when the requested frame is already cached.
 Internal use only.
 */
@property NSUInteger currentFrameIndex;

/**
 Unfortunately, FLAnimatedImageView does not allow for setting the current frame, however, it should work just fine
 when the requested frame is already cached.
 Internal use only.
 */
@property UIImage *currentFrame;

/**
 When the requested internal frame is not cached, set this property for display ASAP.
 Internal use only.
 */
@property BOOL needsDisplayWhenImageBecomesAvailable;

@end

@implementation FLAnimatedImageView (AXExtensions)

- (id)copyWithZone:(struct _NSZone *)zone {
    FLAnimatedImageView *imageView = [super copyWithZone:zone];
    imageView.animatedImage = self.animatedImage;
    imageView.currentFrame = self.currentFrame;
    imageView.currentFrameIndex = self.currentFrameIndex;
    imageView.runLoopMode = self.runLoopMode;
    return imageView;
}

- (void)ax_syncFramesWithImageView:(FLAnimatedImageView *)imageView {
    if (!self.animatedImage || !imageView.animatedImage || ![self.animatedImage.data isEqualToData:imageView.animatedImage.data]) {
        return;
    }
    
    self.currentFrameIndex = imageView.currentFrameIndex;
    self.currentFrame = imageView.currentFrame;
    self.needsDisplayWhenImageBecomesAvailable = YES;
    [self.layer setNeedsDisplay];
}

@end
