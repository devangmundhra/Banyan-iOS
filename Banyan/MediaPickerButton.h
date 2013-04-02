//
//  MediaPickerButton.h
//  Banyan
//
//  Created by Devang Mundhra on 4/1/13.
//
//

#import <UIKit/UIKit.h>

@class MediaPickerButton;

@protocol MediaPickerButtonDelegate <NSObject>

- (void) mediaPickerButtonTapped:(MediaPickerButton *)sender;

@end

@interface MediaPickerButton : UIView
@property (strong, nonatomic) id<MediaPickerButtonDelegate> delegate;
@property (strong, nonatomic) UIImageView *imageView;

@end
