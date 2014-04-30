//
//  ReadSceneViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "ReadPieceViewController.h"
#import "Piece+Stats.h"
#import "Story+Stats.h"
#import <QuartzCore/QuartzCore.h>
#import "AFBanyanAPIClient.h"
#import "Piece+Edit.h"
#import "Piece+Create.h"
#import "User.h"
#import "Piece+Delete.h"
#import "ModifyPieceViewController.h"
#import "BNLabel.h"
#import "BNMisc.h"
#import "Media.h"
#import "UIImageView+BanyanMedia.h"
#import "URBMediaFocusViewController.h"
#import "StoryOverviewController.h"
#import "Piece+Share.h"
#import "CMPopTipView.h"
#import "BButton.h"

static NSString *const deletePieceString = @"Delete piece";
static NSString *const flagPieceString = @"Flag piece";
static NSString *const addPieceString = @"Add a piece";
static NSString *const editPieceString = @"Edit piece";
static NSString *const shareString = @"Share";
static NSString *const cancelString = @"Cancel";
static NSString *const cancelUploadString = @"Cancel upload";
static NSString *const retryUploadString = @"Retry upload";

@interface ReadPieceViewController (UIScrollViewDelegate) <UIScrollViewDelegate>
@end

@interface ReadPieceViewController (StoryOverviewControllerDelegate) <StoryOverviewControllerDelegate>
@end

@interface ReadPieceViewController () <UIActionSheetDelegate, UIAlertViewDelegate, ModifyPieceViewControllerDelegate>

@property (strong, nonatomic) UIView *storyInfoView;
@property (strong, nonatomic) IBOutlet UIScrollView *contentView;
@property (strong, nonatomic) IBOutlet BNLabel *pieceCaptionView;
@property (strong, nonatomic) IBOutlet UITextView *pieceTextView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet BNAudioStreamingPlayer *audioPlayer;

@property (strong, nonatomic) IBOutlet UIView *pieceInfoView;
@property (strong, nonatomic) IBOutlet UIButton *contributorsButton;
@property (strong, nonatomic) IBOutlet UIButton *viewsButton;
@property (strong, nonatomic) IBOutlet UIButton *likesButton;
@property (strong, nonatomic) IBOutlet BNLabel *authorLabel;
@property (strong, nonatomic) IBOutlet BNLabel *timeLabel;
@property (strong, nonatomic) IBOutlet BNLabel *locationLabel;

@property (strong, nonatomic) URBMediaFocusViewController *mediaFocusManager;
@property (nonatomic) BOOL mediaFocusVisible;

@property (strong, nonatomic) BButton *pieceUploadStatusButton;
@end

static NSString *_uploadString;
static NSString *_exclaimString;

@implementation ReadPieceViewController
@synthesize contentView = _contentView;
@synthesize imageView = _imageView;
@synthesize pieceCaptionView = _pieceCaptionView;
@synthesize pieceTextView = _pieceTextView;
@synthesize pieceInfoView = _pieceInfoView;
@synthesize contributorsButton = _contributorsButton;
@synthesize viewsButton = _viewsButton;
@synthesize likesButton = _likesButton;
@synthesize authorLabel = _authorLabel;
@synthesize timeLabel = _timeLabel;
@synthesize locationLabel = _locationLabel;
@synthesize piece = _piece;
@synthesize delegate = _delegate;
@synthesize mediaFocusManager = _mediaFocusManager;
@synthesize audioPlayer = _audioPlayer;
@synthesize storyInfoView = _storyInfoView;
@synthesize mediaFocusVisible;
@synthesize pieceUploadStatusButton = _pieceUploadStatusButton;

+ (void)initialize
{
    NSArray *fontAwesomeStrings = [NSString fa_allFontAwesomeStrings];
    _uploadString = [NSString fa_stringFromFontAwesomeStrings:fontAwesomeStrings forIcon:FAIconSpinner];
    _exclaimString = [NSString fa_stringFromFontAwesomeStrings:fontAwesomeStrings forIcon:FAIconExclamationSign];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) init
{
    self = [super init];
    if (self) {
        // Custom initialization
        // this should never be called directly.
        // initWithPiece should be called
        NSAssert(false, @"Use initWithPiece method to initialize this view controller");
    }
    return self;
}

- (id) initWithPiece:(Piece *)piece
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.piece = piece;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];

    }
    return self;
}

- (void) userLoginStatusChanged
{
    [self refreshUI];
}

#define INFOVIEW_HEIGHT 38.0f
#define BUTTON_SPACING 5.0f
#define TEXT_INSET_BIG 20.0f
#define TEXT_INSET_SMALL 2.0f
#define SIDE_MARGIN 20.0f

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    self.view.frame = frame;

    CGFloat statusBarOffset = [[UIApplication sharedApplication] statusBarFrame].size.height;
    frame = self.view.bounds;
    frame.size.height = INFOVIEW_HEIGHT + statusBarOffset;
    
    self.storyInfoView = [[UIView alloc] initWithFrame:frame];
    self.storyInfoView.backgroundColor = [UIColor clearColor];
    
    UIImage *backArrowImage = [UIImage imageNamed:@"Previous"];
    UIImage *backArrowImageSelected = [UIImage imageNamed:@"Previous_selected"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setExclusiveTouch:YES];
    CGFloat maxButtonDim = MAX(backArrowImage.size.width, backArrowImage.size.height) + BUTTON_SPACING*3;
    backButton.frame = CGRectMake(BUTTON_SPACING, statusBarOffset, floor(maxButtonDim), floor(maxButtonDim));
    [backButton setImage:backArrowImage forState:UIControlStateNormal];
    [backButton setImage:backArrowImageSelected forState:UIControlStateHighlighted];
    [backButton addTarget:self.delegate action:@selector(readPieceViewControllerDoneReading) forControlEvents:UIControlEventTouchUpInside];
    backButton.showsTouchWhenHighlighted = YES;
    [self.storyInfoView addSubview:backButton];
    
    UIImage *settingsImage = [UIImage imageNamed:@"Cog"];
    UIImage *settingsImageSelected = [UIImage imageNamed:@"Cog_selected"];
    maxButtonDim = MAX(settingsImage.size.width, settingsImage.size.height) + BUTTON_SPACING*3;
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setExclusiveTouch:YES];
    settingsButton.frame = CGRectMake(floor(self.view.frame.size.width - maxButtonDim - BUTTON_SPACING), statusBarOffset,
                                      floor(maxButtonDim), floor(maxButtonDim));
    
    [settingsButton setImage:settingsImage forState:UIControlStateNormal];
    [settingsButton setImage:settingsImageSelected forState:UIControlStateHighlighted];
    [settingsButton addTarget:self action:@selector(settingsPopup:) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.showsTouchWhenHighlighted = YES;
    [self.storyInfoView addSubview:settingsButton];
    
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [titleButton setExclusiveTouch:YES];
    titleButton.frame = CGRectMake(CGRectGetMaxX(backButton.frame) + 2*BUTTON_SPACING, statusBarOffset,
                                   CGRectGetMinX(settingsButton.frame) - CGRectGetMaxX(backButton.frame) - 2*BUTTON_SPACING,
                                   CGRectGetHeight(self.storyInfoView.bounds)-statusBarOffset);
    titleButton.titleLabel.minimumScaleFactor = 0.7;
    titleButton.backgroundColor = [UIColor clearColor];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    titleButton.titleLabel.numberOfLines = 2;
    titleButton.showsTouchWhenHighlighted = YES;
    [titleButton addTarget:self action:@selector(storyOverviewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.storyInfoView insertSubview:titleButton atIndex:0]; // Title always at subview index 0
    [self updateStoryTitle];
    [self.view addSubview:self.storyInfoView];
    
    frame = [UIScreen mainScreen].bounds;
    frame.origin.y += CGRectGetMaxY(self.storyInfoView.frame);
    frame.size.height -= CGRectGetMaxY(self.storyInfoView.frame);
    self.contentView = [[UIScrollView alloc] initWithFrame:frame];
    self.contentView.backgroundColor = BANYAN_WHITE_COLOR;
    self.contentView.delegate = self;
    [self.view addSubview:self.contentView];

    self.pieceInfoView = [[UIView alloc] initWithFrame:CGRectZero];
    self.authorLabel = [[BNLabel alloc] initWithFrame:CGRectZero];
    self.timeLabel = [[BNLabel alloc] initWithFrame:CGRectZero];
    self.locationLabel = [[BNLabel alloc] initWithFrame:CGRectZero];

    self.likesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.likesButton.exclusiveTouch = YES;
    [self.likesButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.pieceInfoView addSubview:self.authorLabel];
    [self.pieceInfoView addSubview:self.timeLabel];
    [self.pieceInfoView addSubview:self.likesButton];
    [self.pieceInfoView addSubview:self.locationLabel];
    [self.contentView addSubview:self.pieceInfoView];
    
    // Media focus manager
    self.mediaFocusManager = [[URBMediaFocusViewController alloc] init];
    self.mediaFocusManager.shouldDismissOnTap = YES;
    
    // Audip player
    self.audioPlayer = [[BNAudioStreamingPlayer alloc] init];
    [self addChildViewController:self.audioPlayer];
    [self.contentView addSubview:self.audioPlayer.view];
    [self.audioPlayer didMoveToParentViewController:self];
    
    // Image view
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self addGestureRecognizerToFocusOnImageView:self.imageView];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.imageView.backgroundColor = BANYAN_BLACK_COLOR;
    [self.contentView insertSubview:self.imageView belowSubview:self.audioPlayer.view];
    
    // Caption
    self.pieceCaptionView = [[BNLabel alloc] initWithFrame:CGRectZero];
    self.pieceCaptionView.lineBreakMode = NSLineBreakByWordWrapping;
    self.pieceCaptionView.backgroundColor = [UIColor clearColor];
    self.pieceCaptionView.font = [UIFont fontWithName:@"Roboto-BoldCondensed" size:26];
    self.pieceCaptionView.minimumScaleFactor = 0.7;
    self.pieceCaptionView.textAlignment = NSTextAlignmentLeft;
    self.pieceCaptionView.textEdgeInsets = UIEdgeInsetsMake(0, TEXT_INSET_BIG, 0, TEXT_INSET_BIG);
    self.pieceCaptionView.numberOfLines = 4;
    [self.contentView addSubview:self.pieceCaptionView];
    
    // Description
    self.pieceTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.pieceTextView.editable = NO;
    self.pieceTextView.backgroundColor = [UIColor clearColor];
    self.pieceTextView.font = [UIFont fontWithName:@"Roboto" size:18];
    self.pieceTextView.textAlignment = NSTextAlignmentLeft;
    self.pieceTextView.scrollEnabled = NO;
    [self.contentView addSubview:self.pieceTextView];

    // Piece upload status button
    frame = [UIScreen mainScreen].bounds;
    self.pieceUploadStatusButton = [[BButton alloc] initWithFrame:CGRectMake(0, 0, 90, 36) color:[UIColor bb_successColorV3] style:BButtonStyleBootstrapV3];
    [self.pieceUploadStatusButton.titleLabel setFont:[UIFont fontWithName:@"Roboto" size:11]];
    [self.pieceUploadStatusButton.titleLabel setTextAlignment:NSTextAlignmentRight];
    [self.pieceUploadStatusButton setTitle:@"Local " forState:UIControlStateNormal];
    [self.pieceUploadStatusButton addAwesomeIcon:FAIconCircle beforeTitle:NO];
    self.pieceUploadStatusButton.frame = CGRectOffset(self.pieceUploadStatusButton.frame,
                                                      CGRectGetWidth(frame) - CGRectGetWidth(self.pieceUploadStatusButton.frame) - BUTTON_SPACING,
                                                      CGRectGetHeight(frame) - CGRectGetHeight(self.pieceUploadStatusButton.frame) - BUTTON_SPACING);
    self.pieceUploadStatusButton.alpha = 0.8;
    self.pieceUploadStatusButton.hidden = YES;
    [self.pieceUploadStatusButton addTarget:self action:@selector(pieceUploadActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:self.pieceUploadStatusButton aboveSubview:self.contentView];
    
    [self refreshUI];
    
    // Do any additional setup after loading the view from its nib.
    // Update Stats
    [self.piece setViewedWithCompletionBlock:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogInNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogOutNotification
                                               object:nil];
    
    BNLogInfo(@"Reading piece with objectId %@ and shortText %@", REPLACE_NIL_WITH_EMPTY_STRING(self.piece.bnObjectId), REPLACE_NIL_WITH_EMPTY_STRING(self.piece.shortText));
}

- (void) addGestureRecognizerToFocusOnImageView:(UIImageView *)view
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFocusView:)];
	tapRecognizer.numberOfTapsRequired = 1;
	tapRecognizer.numberOfTouchesRequired = 1;
	[view addGestureRecognizer:tapRecognizer];
    view.userInteractionEnabled = YES;
}

- (void) addGestureRecognizerToContentView:(UIGestureRecognizer *)gR
{
    if (gR) {
        [self.contentView addGestureRecognizer:gR];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Read Piece screen"];
    if ([self.delegate respondsToSelector:@selector(setCurrentPiece:)]) {
        [self.delegate performSelector:@selector(setCurrentPiece:) withObject:self.piece];
    }
    
    [self addGestureRecognizerToContentView:[self.delegate dismissBackPanGestureRecognizer]];
    [self addGestureRecognizerToContentView:[self.delegate dismissAheadPanGestureRecognizer]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *firstTimeDict = [[defaults dictionaryForKey:BNUserDefaultsFirstTimeActionsDict] mutableCopy];
    if (![firstTimeDict objectForKey:BNUserDefaultsFirstTimeStoryReaderOpen] ) {
        [firstTimeDict setObject:[NSNumber numberWithBool:YES] forKey:BNUserDefaultsFirstTimeStoryReaderOpen];
        [defaults setObject:firstTimeDict forKey:BNUserDefaultsFirstTimeActionsDict];
        [defaults synchronize];
        CMPopTipView *popTipView = [[CMPopTipView alloc] initWithMessage:@"Tap here to get information about the story"];
        SET_CMPOPTIPVIEW_APPEARANCES(popTipView);
        [popTipView presentPointingAtView:[self.storyInfoView.subviews objectAtIndex:0] inView:self.view animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.audioPlayer pause:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.mediaFocusManager cancelURLConnectionIfAny];
}

- (void)refreshUI
{
    self.pieceCaptionView.frame = CGRectZero;
    self.pieceTextView.frame = CGRectZero;
    self.imageView.frame = CGRectZero;
    self.audioPlayer.view.frame = CGRectZero; self.audioPlayer.view.hidden = YES;
    
    Media *imageMedia = [Media getMediaOfType:@"gif" inMediaSet:self.piece.media];
    if (![imageMedia.localURL length] && ![imageMedia.remoteURL length])
        imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
    Media *audioMedia = [Media getMediaOfType:@"audio" inMediaSet:self.piece.media];
    
    // Allocate custom parts of the view depending on what the piece contains
    BOOL hasAudio = [audioMedia.localURL length] || [audioMedia.remoteURL length];
    BOOL hasImage = [imageMedia.localURL length] || [imageMedia.remoteURL length];
    BOOL hasCaption = [self.piece.shortText length];
    BOOL hasDescription = [self.piece.longText length];
    
    // If there is audio, its always at the top of the content.
    // If there is no long text full screen image, else image size of half size
    // If there is an image and no long text, pieceInfo/caption is at the bottom
    // If there is no image or long text, pieceInfo/caption in the middle
    // Long text always below caption
    CGRect frame = [UIScreen mainScreen].bounds;
    CGSize csize = self.contentView.contentSize;
    csize.height = 0;

    if (hasAudio) {
        frame = CGRectMake(0, 0, CGRectGetWidth(frame), 50);
        self.audioPlayer.view.frame = frame; self.audioPlayer.view.hidden = NO;
        csize.height = CGRectGetMaxY(self.audioPlayer.view.frame);
        [self.contentView bringSubviewToFront:self.audioPlayer.view];
    }
    
    if (hasImage) {
        frame = [UIScreen mainScreen].bounds;
        if (hasDescription) {
            frame.size.height = frame.size.height/2;
        }
        self.imageView.frame = frame;
        self.imageView.contentMode = hasDescription ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
        csize.height = CGRectGetMaxY(self.imageView.frame);
    }
    // Add author/date/location/stats here
    {
        frame = [UIScreen mainScreen].bounds;
        if (hasImage && !hasDescription) {
            frame = CGRectMake(0, 0.5*frame.size.height, frame.size.width, 40);
        } else {
            frame = CGRectMake(0, MAX(CGRectGetMaxY(self.imageView.frame), CGRectGetMaxY(self.audioPlayer.view.frame)), frame.size.width, 40);
        }
        self.pieceInfoView.frame = frame;
        [self.contentView bringSubviewToFront:self.pieceInfoView];
        // author label
        self.authorLabel.textEdgeInsets = UIEdgeInsetsMake(0, TEXT_INSET_BIG, 0, TEXT_INSET_SMALL);
        self.authorLabel.text = self.piece.author.name;
        self.authorLabel.font = [UIFont fontWithName:@"Roboto" size:16];
        self.authorLabel.minimumScaleFactor = 0.8;
        self.authorLabel.backgroundColor= [UIColor clearColor];
        self.authorLabel.textAlignment = NSTextAlignmentLeft;
        self.authorLabel.numberOfLines = 2;
        [self.authorLabel sizeToFit];
        
        if ([BanyanAppDelegate loggedIn])
        {
            frame = [UIScreen mainScreen].bounds;
            // like button
            self.likesButton.frame = CGRectMake(CGRectGetMaxX(frame)-44-3*TEXT_INSET_SMALL, 0, 44, floor(CGRectGetHeight(self.authorLabel.frame)));
            self.likesButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
            [self.likesButton setImageEdgeInsets:UIEdgeInsetsMake(5, 4, 5, 4)];
            [self.likesButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 3*TEXT_INSET_SMALL, 0, 0)];
            [self.likesButton setTitleColor:BANYAN_PINK_COLOR forState:UIControlStateNormal];
            [self togglePieceLikeButtonLabel];
        }
        // date label
        self.timeLabel.text = [NSString stringWithFormat:@"%@",[[BNMisc dateTimeFormatter] stringFromDate:self.piece.createdAt]];
        self.timeLabel.textEdgeInsets = UIEdgeInsetsMake(0, TEXT_INSET_BIG, 0, TEXT_INSET_SMALL);
        self.timeLabel.font = [UIFont fontWithName:@"Roboto-Condensed" size:12];
        self.timeLabel.minimumScaleFactor = 0.8;
        self.timeLabel.backgroundColor = [UIColor clearColor];
        self.timeLabel.textAlignment = NSTextAlignmentLeft;
        [self.timeLabel sizeToFit];
        frame = self.timeLabel.frame;
        frame.origin = CGPointMake(0, CGRectGetMaxY(self.authorLabel.frame));
        self.timeLabel.frame = frame;
        
        // location label
        if ([self.piece.location.name length]) {
            self.locationLabel.text = [NSString stringWithFormat:@"at %@", self.piece.location.name];
            self.locationLabel.textEdgeInsets = UIEdgeInsetsMake(0, TEXT_INSET_SMALL, 0, TEXT_INSET_SMALL);
            self.locationLabel.font = [UIFont fontWithName:@"Roboto-Condensed" size:12];
            self.locationLabel.minimumScaleFactor = 0.8;
            self.locationLabel.backgroundColor = [UIColor clearColor];
            self.locationLabel.textAlignment = NSTextAlignmentLeft;
            self.locationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            frame = self.locationLabel.frame;
            frame.origin = CGPointMake(CGRectGetMaxX(self.timeLabel.frame), CGRectGetMaxY(self.authorLabel.frame));
            frame.size.height = CGRectGetHeight(self.timeLabel.frame);
            frame.size.width = CGRectGetWidth([UIScreen mainScreen].bounds) - frame.origin.x - SIDE_MARGIN;
            self.locationLabel.frame = frame;
        }
        [self.pieceInfoView sizeToFit];
    }
    if (hasCaption) {
        frame = [UIScreen mainScreen].bounds;
        frame = CGRectMake(0, CGRectGetMaxY(self.pieceInfoView.frame), frame.size.width, 100);
        
        CGSize maximumLabelSize = frame.size;
        maximumLabelSize.width -= 2*TEXT_INSET_BIG; // adjust for the textInsets
        CGSize expectedLabelSize = [self.piece.shortText boundingRectWithSize:maximumLabelSize
                                                                      options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                                                   attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-BoldCondensed" size:26]}
                                                                      context:nil].size;
        frame.size.height = expectedLabelSize.height;
        self.pieceCaptionView.frame = frame;
        
        self.pieceCaptionView.text = self.piece.shortText;
        csize.height = CGRectGetMaxY(self.pieceCaptionView.frame); // overwrite because caption will always be lower than image.
    }
    if (hasDescription) {
        CGPoint descOrigin;
        if (hasCaption) {
            descOrigin = CGPointMake(SIDE_MARGIN, CGRectGetMaxY(self.pieceCaptionView.frame));
        } else {
            descOrigin = CGPointMake(SIDE_MARGIN, CGRectGetMaxY(self.pieceInfoView.frame));
        }
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.alignment = self.pieceTextView.textAlignment;
        
        frame = [self.piece.longText boundingRectWithSize:CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds)-2*20, FLT_MAX)
                                                  options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:18],
                                                            NSParagraphStyleAttributeName: paraStyle}
                                                  context:nil];
        frame.origin = descOrigin;
        frame.size.height += 2*TEXT_INSET_BIG;
        frame.size.width = CGRectGetWidth([UIScreen mainScreen].bounds)-2*SIDE_MARGIN;
        self.pieceTextView.frame = frame;
        self.pieceTextView.text = self.piece.longText;
        csize.height += CGRectGetHeight(self.pieceTextView.frame);
    }
    self.contentView.contentSize = csize;
    [self.contentView setContentOffset:CGPointMake(0,0)];

    if (hasAudio) {
        if ([audioMedia.remoteURL length]) {
            [self.audioPlayer loadWithURL:audioMedia.remoteURL];
        } else {
            [self.audioPlayer loadWithURL:audioMedia.localURL];
        }
    }
    
    if (hasImage) {
        [self.imageView showMedia:imageMedia includeThumbnail:NO withPostProcess:nil];
    } else {
        [self.imageView setImageWithURL:nil];
        [self.imageView cancelCurrentImageLoad];
    }
    
    if (hasDescription || !hasImage) {
        self.pieceCaptionView.textColor =
        self.pieceTextView.textColor = BANYAN_BLACK_COLOR;
        self.authorLabel.textColor =
        self.timeLabel.textColor = BANYAN_DARKGRAY_COLOR;
        self.locationLabel.textColor = BANYAN_DARKGRAY_COLOR;
    } else {
        self.pieceCaptionView.textColor =
        self.pieceTextView.textColor = BANYAN_WHITE_COLOR;
        self.authorLabel.textColor =
        self.timeLabel.textColor = BANYAN_WHITE_COLOR;
        self.locationLabel.textColor = BANYAN_WHITE_COLOR;
    }
    
    [self.contributorsButton setTitle:@"Contributors" forState:UIControlStateNormal];
    [self.contributorsButton setEnabled:NO];
    
    // Upload status
    if (self.piece.remoteStatus == RemoteObjectStatusPushing) {
        [self.pieceUploadStatusButton setTitle:@"Uploading... " forState:UIControlStateNormal];
        [self.pieceUploadStatusButton addAwesomeIcon:FAIconSpinner beforeTitle:NO];
        [self.pieceUploadStatusButton setColor:[UIColor bb_successColorV3]];
        self.pieceUploadStatusButton.hidden = NO;
    } else if (self.piece.remoteStatus == RemoteObjectStatusFailed) {
        [self.pieceUploadStatusButton setTitle:@"Upload Failed " forState:UIControlStateNormal];
        [self.pieceUploadStatusButton addAwesomeIcon:FAIconExclamationSign beforeTitle:NO];
        [self.pieceUploadStatusButton setColor:[UIColor bb_dangerColorV3]];
        self.pieceUploadStatusButton.hidden = NO;
    } else {
        self.pieceUploadStatusButton.hidden = YES;
    }
}

- (void) updateStoryTitle
{
    if (!self.piece.story) {
        // In case the story was deleted
        return;
    }
    
    NSUInteger currentPieceNum = [self.piece.story.pieces indexOfObject:self.piece];

    UIButton *titleButton = [self.storyInfoView.subviews objectAtIndex:0];
    NSAttributedString *titleString = nil;
    
    if (self.piece.story.title.length <= 20) {
        titleString = [[NSAttributedString alloc] initWithString:self.piece.story.title
                                        attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                     NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR}];
    } else {
        titleString = [[NSAttributedString alloc] initWithString:self.piece.story.title
                                        attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:12],
                                                     NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR}];
    }
    
    NSAttributedString *pageString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\rpiece %d/%d", currentPieceNum+1, self.piece.story.length]
                                                                     attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                  NSForegroundColorAttributeName: BANYAN_GRAY_COLOR}];
    NSMutableAttributedString *pageAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:titleString];
    [pageAttrString appendAttributedString:pageString];
    
    NSAttributedString *tapString = [[NSAttributedString alloc] initWithString:@"\rtap for story information"
                                                                     attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                  NSForegroundColorAttributeName: BANYAN_GRAY_COLOR}];
    
    NSMutableAttributedString *tapAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:titleString];
    [tapAttrString appendAttributedString:tapString];
    
    // Delay execution of my block for 2 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [titleButton setAttributedTitle:pageAttrString forState:UIControlStateNormal];
    });
    [titleButton setAttributedTitle:tapAttrString forState:UIControlStateNormal];
}

#pragma mark notifications
- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (!self.piece) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
    
    if ([insertedObjects containsObject:self.piece] || [updatedObjects containsObject:self.piece]) {
        [self refreshUI];
    }
    
    if (self.piece.story && [updatedObjects containsObject:self.piece.story]) {
        [self updateStoryTitle];
    }
}

# pragma mark target actions
- (IBAction)pieceUploadActionButtonPressed:(id)sender
{
    BNLogInfo(@"piece upload action button pressed for status %@", self.piece.remoteStatusNumber);
    if (self.piece.remoteStatus == RemoteObjectStatusPushing) {
        [self cancelPieceUploadAlert:sender];
    } else if (self.piece.remoteStatus == RemoteObjectStatusFailed) {
        [self retryPieceUploadAlert:sender];
    }
}

- (void)cancelPieceUploadAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:cancelUploadString
                                                        message:@"Do you want to cancel the upload of any changes to this piece?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)retryPieceUploadAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:retryUploadString
                                                        message:@"Retry synchronization of any changes to this piece?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)settingsPopup:(id)sender
{
    UIActionSheet *actionSheet = nil;
    if (self.piece.story.canContribute && [BanyanAppDelegate loggedIn]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelString
                                    destructiveButtonTitle:self.piece.author.userId == [BNSharedUser currentUser].userId ? deletePieceString : flagPieceString
                                         otherButtonTitles:addPieceString, editPieceString, shareString, nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelString
                                    destructiveButtonTitle:flagPieceString
                                         otherButtonTitles:shareString, nil];
    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.contentView];
}

- (void)storyOverviewButtonPressed:(id)sender
{
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    StoryOverviewController *storyOverviewVC = [[StoryOverviewController alloc] initWithStory:self.piece.story];
    storyOverviewVC.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:storyOverviewVC];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void) deletePiece:(Piece *)piece
{
    Story *story = self.piece.story;
    NSUInteger curPieceIndexNum = [story.pieces indexOfObject:self.piece];
    NSUInteger turnToPieceAtIndex = NSNotFound;
    if (curPieceIndexNum != [self.piece.story.pieces count]-1) {
        turnToPieceAtIndex = curPieceIndexNum;
    } else { // This was the last piece
        turnToPieceAtIndex = curPieceIndexNum - 1;
    }
    
    __weak ReadPieceViewController *wself = self;
    [Piece deletePiece:self.piece completion:^{
        if (!story.pieces.count) {
            [wself.delegate readPieceViewControllerDoneReading];
        } else {
            [wself.delegate readPieceViewControllerFlipToPieceAtIndex:turnToPieceAtIndex];
        }
    }];
}

#pragma mark Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // DO NOTHING ON CANCEL
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:deletePieceString]) {
        // Delete piece
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:deletePieceString
                                                            message:@"Do you want to delete this piece?"
                                                           delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        
        [alertView show];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:flagPieceString]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:flagPieceString
                                                            message:@"Do you want to report this piece as inappropriate?\rYou can optionally specify a brief message for the reviewers."
                                                           delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        [alertView show];    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:addPieceString]) {
        Piece *piece = [Piece newPieceDraftForStory:self.piece.story];
        ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:piece];
        addPieceViewController.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
        [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:editPieceString]) {
        ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:self.piece];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
        //    addSceneViewController.delegate = self;
        [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:shareString]) {
        // Share
        [self.piece shareOnFacebook];
    }
    else {
        BNLogWarning(@"StoryReaderController_actionSheetclickedButtonAtIndex %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
    }
}

# pragma mark AlertVew Delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:deletePieceString] && buttonIndex==1) {
        [self deletePiece:self.piece];
    } else if ([alertView.title isEqualToString:flagPieceString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        NSString *message = [alertView textFieldAtIndex:0].text;
        [self.piece flaggedWithMessage:message];
    } else if ([alertView.title isEqualToString:cancelUploadString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.piece cancelAnyOngoingOperation];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"piece upload action" label:@"cancel" value:nil];
    } else if ([alertView.title isEqualToString:retryUploadString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.piece uploadFailedRemoteObject];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"piece upload action" label:@"retry" value:nil];
    }
}

- (void)togglePieceLikeButtonLabel
{
    UIImage *heartImage = nil;
    if (self.piece.likeActivityResourceUri.length) {
        heartImage = [UIImage imageNamed:@"heartSymbolPink"];
    }
    else {
        heartImage = [UIImage imageNamed:@"heartSymbolHollow"];
    }
    [self.likesButton setImage:heartImage forState:UIControlStateNormal];
    [self.likesButton setTitle:[NSString stringWithFormat:@"%d", self.piece.numberOfLikes ] forState:UIControlStateNormal];
}

- (IBAction)likeButtonPressed:(UIButton *)sender
{
    __weak UIButton *wLikeButton = sender;
    __weak ReadPieceViewController *wself = self;
    
    wLikeButton.enabled = NO;
    void (^likeCompletionBlock)(bool succeeded, NSError *error) = ^(bool succeeded, NSError *error) {
        wLikeButton.enabled = YES;
        if (succeeded) {
            [wself togglePieceLikeButtonLabel];
            [BNMisc sendGoogleAnalyticsSocialInteractionWithNetwork:@"Banyan" action:@"like" target:[NSString stringWithFormat:@"Piece_%@", wself.piece.bnObjectId]];
        }
    };
    
    if (self.piece.likeActivityResourceUri.length) {
        [self.piece unlikeWithCompletionBlock:likeCompletionBlock];
    } else {
        [self.piece likeWithCompletionBlock:likeCompletionBlock];
    }
}

- (void)showFocusView:(UITapGestureRecognizer *)gestureRecognizer
{
    NSAssert1([gestureRecognizer.view isKindOfClass:[UIImageView class]], @"gestureRecognizer not on imageView", [gestureRecognizer.view class]);
    UIImageView *imageView = (UIImageView *)gestureRecognizer.view;
    UIImage *image = imageView.image;
    
    if (!image)
        return;
    
    // Don't try to get image from the network. That code seems to be a little fragile.
    // In any case, the pie completion UI of image downloading is pretty good. So just wait till the image
    // actually downloads before doing anything
    [self.mediaFocusManager showImage:image fromView:imageView];
}

#pragma mark ModifyPieceViewControllerDelegate
- (void)modifyPieceViewController:(ModifyPieceViewController *)controller didFinishAddingPiece:(Piece *)piece
{
    [self.delegate readPieceViewControllerFlipToPieceAtIndex:[piece.story.pieces indexOfObject:piece]];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation ReadPieceViewController (StoryOverviewControllerDelegate)

- (void)storyOverviewControllerSelectedPiece:(Piece *)piece
{
    [self.delegate readPieceViewControllerFlipToPieceAtIndex:[piece.story.pieces indexOfObject:piece]];
}

- (void)storyOverviewControllerDeletedStory
{
    // Just return from here
    [self.delegate readPieceViewControllerDoneReading];
}

@end