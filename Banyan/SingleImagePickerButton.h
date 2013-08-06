//
//  SingleImagePickerButton.h
//  Banyan
//
//  Created by Devang Mundhra on 8/5/13.
//
//

#import <UIKit/UIKit.h>

@class SingleImagePickerButton;

@protocol SingleImagePickerButtonDelegate <NSObject>

- (void) singleImagePickerButtonTapped:(SingleImagePickerButton *)sender;

@end

@interface SingleImagePickerButton : UIView

@property (strong, nonatomic) id<SingleImagePickerButtonDelegate> delegate;
@property (strong, nonatomic) UIImageView *imageView;

@end
