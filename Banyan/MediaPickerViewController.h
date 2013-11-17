//
//  MediaPickerViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 4/1/13.
//
//

#import <UIKit/UIKit.h>
#import "AFPhotoEditorController.h"
#import "UIImage+ResizeAdditions.h"
#import <AssetsLibrary/AssetsLibrary.h>

extern NSString *const MediaPickerControllerSourceTypeCamera;
extern NSString *const MediaPickerControllerSourceTypePhotoLib;

extern NSString *const MediaPickerViewControllerInfoURL;
extern NSString *const MediaPickerViewControllerInfoImage;

@class MediaPickerViewController;

@protocol MediaPickerViewControllerDelegate <NSObject>

- (void) mediaPicker:(MediaPickerViewController *)mediaPicker finishedPickingMediaWithInfo:(NSDictionary *)info;
- (void) mediaPickerDidCancel:(MediaPickerViewController *)mediaPicker;

@end

@interface MediaPickerViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AFPhotoEditorControllerDelegate>

@property (weak, nonatomic) id<MediaPickerViewControllerDelegate> delegate;

- (BOOL) shouldStartCameraController;
- (BOOL) shouldStartPhotoLibraryPickerController;

@end
