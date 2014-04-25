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
#import "CMPopTipView.h"

@interface BNImageCropperViewController ()
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic,weak) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editThumbnailButton;

@end

@implementation BNImageCropperViewController
@synthesize  saveButton = _saveButton;
@synthesize editThumbnailButton = _editThumbnailButton;
@synthesize toolbar = _toolbar;

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
    
    // Do any additional setup after loading the view from its nib.
    self.title = @"Edit thumnail";
    self.cropSize = MEDIA_THUMBNAIL_SIZE;
    self.minimumScale = 0.001;
    self.maximumScale = 10;
    self.checkBounds = NO;
    self.rotateEnabled = NO;
    self.outputWidth = self.cropSize.width;
    
    NSAttributedString *titleString = nil;
    titleString = [[NSAttributedString alloc] initWithString:@"Edit thumbnail"
                                                  attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                               NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR}];
    NSAttributedString *tapString = [[NSAttributedString alloc] initWithString:@"\rtap for more information"
                                                                    attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                 NSForegroundColorAttributeName: BANYAN_GRAY_COLOR}];
    
    NSMutableAttributedString *tapAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:titleString];
    [tapAttrString appendAttributedString:tapString];
    
    UIButton *titleButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [titleButton setAttributedTitle:tapAttrString forState:UIControlStateNormal];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    titleButton.titleLabel.numberOfLines = 2;
    [titleButton addTarget:self action:@selector(titlePressed:) forControlEvents:UIControlEventTouchUpInside];
    [titleButton sizeToFit];
    titleButton.center = self.toolbar.center;
    self.editThumbnailButton.customView = titleButton;
    [self reset:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Image Cropper"];
}

- (IBAction)titlePressed:(id)sender
{
    CMPopTipView *popTipView = [[CMPopTipView alloc] initWithTitle:@"Why thumbnails?"
                                                           message:@"Thumbnails are used to show the important parts of the image when a user is quickly scrolling through all the pieces"];
    SET_CMPOPTIPVIEW_APPEARANCES(popTipView);
    [popTipView presentPointingAtBarButtonItem:self.editThumbnailButton animated:NO];
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
