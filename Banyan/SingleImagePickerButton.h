//
//  SingleImagePickerButton.h
//  Banyan
//
//  Created by Devang Mundhra on 8/5/13.
//
//

#import <UIKit/UIKit.h>

@class SingleImagePickerButton;

@interface SingleImagePickerButton : UIView

- (void) addTargetForCamera:(id)target action:(SEL)action;
- (void) addTargetForPhotoGallery:(id)target action:(SEL)action;
- (void) addTargetToDeleteImage:(id)target action:(SEL)action;
- (void) setImage:(UIImage *)image;
- (void) unsetImage;

@end
