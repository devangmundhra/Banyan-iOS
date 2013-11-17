//
//  MediaPickerButton.h
//  Banyan
//
//  Created by Devang Mundhra on 4/1/13.
//
//

#import <UIKit/UIKit.h>

@class MediaPickerButton;
@class Media;

@protocol MediaPickerButtonDelegate <NSObject>

- (void) addNewMedia:(MediaPickerButton *)sender;
- (void) deletePreviousMedia:(Media *)media;

@optional
- (NSOrderedSet *)listOfMediaForMediaPickerButton;
- (void) updateMediaFromNumber:(NSUInteger)fromNumber toNumber:(NSUInteger)toNumber;

@end

@interface MediaPickerButton : UIView <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) id<MediaPickerButtonDelegate> delegate;

- (void) reloadList;

@end

@interface MediaPickerButtonTableViewCell : UITableViewCell
@property (weak, nonatomic) Media *media;
@end