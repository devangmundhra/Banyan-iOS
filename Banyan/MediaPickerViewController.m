//
//  MediaPickerViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 4/1/13.
//
//

#import "MediaPickerViewController.h"
#import "MBProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>

NSString *const MediaPickerControllerSourceTypeCamera = @"Camera";
NSString *const MediaPickerControllerSourceTypePhotoLib = @"Photo Library";

NSString *const MediaPickerViewControllerInfoURL = @"MediaPickerViewControllerInfoURL";
NSString *const MediaPickerViewControllerInfoImage = @"MediaPickerViewControllerInfoImage";

@interface MediaPickerViewController ()

@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) UIImage *image;
@property (nonatomic) BOOL pickerIsCamera;
@end

@implementation MediaPickerViewController

@synthesize imageURL = _imageURL;
@synthesize image = _image;
@synthesize delegate = _delegate;
@synthesize pickerIsCamera;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (BOOL)shouldStartCameraController {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:
             UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        
    } else {
        return NO;
    }
    
    cameraUI.allowsEditing = NO;
    cameraUI.showsCameraControls = YES;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

- (BOOL)shouldStartPhotoLibraryPickerController {
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
         && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
        && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
               && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else {
        return NO;
    }
    
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

# pragma mark - Image Picker
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    pickerIsCamera = ([picker sourceType] == UIImagePickerControllerSourceTypeCamera);
    [self dismissViewControllerAnimated:NO completion:^{
        // If the image view controller is completed successfully, we don't really need to keep this saved
        // as a presented screen will not be affected by mem warning.
        [self displayEditorForImage:[info objectForKey:@"UIImagePickerControllerOriginalImage"]];
    }];
    
    self.imageURL = (NSURL *)[info objectForKey:@"UIImagePickerControllerReferenceURL"];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate)
            [self.delegate mediaPickerDidCancel:self];
    }];
}

# pragma mark AFPhotoEditorController delegate methods
- (void) displayEditorForImage:(UIImage *)image
{
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:image];
    [editorController setDelegate:self];
    [self presentViewController:editorController animated:YES completion:nil];
}

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    // Handle the result image here
    [self dismissViewControllerAnimated:YES completion:nil];
    self.image = image;
    AFPhotoEditorSession *session = editor.session;
    
    if (session.modified || pickerIsCamera)
    {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Saving Picture";
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
        
        [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error )
         {
             if (assetURL) {
                 NSLog(@"%s Image saved to photo albums %@", __PRETTY_FUNCTION__, assetURL);
                 self.imageURL = assetURL;
             } else {
                 NSLog(@"%s Error saving image: %@", __PRETTY_FUNCTION__, error);
             }
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:self.imageURL, MediaPickerViewControllerInfoURL, self.image, MediaPickerViewControllerInfoImage, nil];
             if (self.delegate)
                 [self.delegate mediaPicker:self finishedPickingMediaWithInfo:infoDict];
         }];
    } else {
        NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:self.imageURL, MediaPickerViewControllerInfoURL, self.image, MediaPickerViewControllerInfoImage, nil];
        if (self.delegate)
            [self.delegate mediaPicker:self finishedPickingMediaWithInfo:infoDict];
    }
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    // Handle cancelation here
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate)
            [self.delegate mediaPickerDidCancel:self];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end