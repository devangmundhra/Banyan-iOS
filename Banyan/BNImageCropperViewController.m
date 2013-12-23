//
//  BNImageCropperViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 12/22/13.
//
//

#import "HFImageEditorViewController+Private.h"
#import "BNImageCropperViewController.h"
#import "Media.h"

@interface BNImageCropperViewController ()
@property (nonatomic,strong) IBOutlet UIBarButtonItem *saveButton;

@end

@implementation BNImageCropperViewController
@synthesize  saveButton = _saveButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.cropSize = CGSizeMake(MEDIA_THUMBNAIL_SIZE, MEDIA_THUMBNAIL_SIZE);
        self.minimumScale = 0.2;
        self.maximumScale = 10;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Hooks
- (void)startTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:49/255.0f blue:98/255.0f alpha:1];
}

- (void)endTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:128/255.0f blue:1 alpha:1];
}


@end
