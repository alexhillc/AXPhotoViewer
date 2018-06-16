//
//  UIImageView+AXExtensions.h
//  AXPhotoViewer
//
//  Created by Alex Hill on 3/10/18.
//

@import UIKit;

@interface UIImageView (AXExtensions)

/**
 Copy a UIImageView's with its base attributes
 
 @return A copy of the UIImageView
 @note Does not conform to NSCopying (may conflict with another definition)
 */
- (__kindof UIImageView *_Nonnull)ax_copy;

@end
