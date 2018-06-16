//
//  UIImageView+AXExtensions.m
//  AXPhotoViewer
//
//  Created by Alex Hill on 3/10/18.
//

#import "UIImageView+AXExtensions.h"

@implementation UIImageView (AXExtensions)

- (UIImageView *)ax_copy {
    UIImageView *imageView = [[[self class] alloc] init];
    imageView.image = self.image;
    imageView.highlightedImage = self.highlightedImage;
    imageView.animationImages = self.animationImages;
    imageView.highlightedAnimationImages = self.highlightedAnimationImages;
    imageView.animationDuration = self.animationDuration;
    imageView.animationRepeatCount = self.animationRepeatCount;
    imageView.highlighted = self.isHighlighted;
    imageView.tintColor = self.tintColor;
    imageView.transform = self.transform;
    imageView.frame = self.frame;
    imageView.layer.cornerRadius = self.layer.cornerRadius;
    imageView.layer.masksToBounds = self.layer.masksToBounds;
    imageView.contentMode = self.contentMode;
    return imageView;
}

@end
