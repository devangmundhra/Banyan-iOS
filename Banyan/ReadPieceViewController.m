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

@interface ReadPieceViewController (UIScrollViewDelegate) <UIScrollViewDelegate>
@end

@interface ReadPieceViewController (StoryOverviewControllerDelegate) <StoryOverviewControllerDelegate>
@end

@interface ReadPieceViewController () <UIActionSheetDelegate, ModifyPieceViewControllerDelegate>

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
@property (strong, nonatomic) IBOutlet UIButton *commentsButton;
@property (strong, nonatomic) IBOutlet BNLabel *authorLabel;
@property (strong, nonatomic) IBOutlet BNLabel *timeLabel;
@property (strong, nonatomic) IBOutlet BNLabel *locationLabel;

@property (strong, nonatomic) URBMediaFocusViewController *mediaFocusManager;
@property (nonatomic) BOOL mediaFocusVisible;
@end

@implementation ReadPieceViewController
@synthesize contentView = _contentView;
@synthesize imageView = _imageView;
@synthesize pieceCaptionView = _pieceCaptionView;
@synthesize pieceTextView = _pieceTextView;
@synthesize pieceInfoView = _pieceInfoView;
@synthesize contributorsButton = _contributorsButton;
@synthesize viewsButton = _viewsButton;
@synthesize likesButton = _likesButton;
@synthesize commentsButton = _commentsButton;
@synthesize authorLabel = _authorLabel;
@synthesize timeLabel = _timeLabel;
@synthesize locationLabel = _locationLabel;
@synthesize piece = _piece;
@synthesize delegate = _delegate;
@synthesize mediaFocusManager = _mediaFocusManager;
@synthesize audioPlayer = _audioPlayer;
@synthesize storyInfoView = _storyInfoView;
@synthesize mediaFocusVisible;

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
        if (HAVE_ASSERTS)
            assert(false);
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
    
    UIImage *backArrowImage = [UIImage imageNamed:@"backArrow"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setExclusiveTouch:YES];
    CGFloat maxButtonDim = MAX(backArrowImage.size.width, backArrowImage.size.height) + BUTTON_SPACING*3;
    backButton.frame = CGRectMake(BUTTON_SPACING, statusBarOffset, floor(maxButtonDim), floor(maxButtonDim));
    [backButton setImage:backArrowImage forState:UIControlStateNormal];
    [backButton addTarget:self.delegate action:@selector(readPieceViewControllerDoneReading) forControlEvents:UIControlEventTouchUpInside];
    backButton.showsTouchWhenHighlighted = YES;
    [backButton.layer setBorderWidth:0.5f];
    [backButton.layer setBorderColor:BANYAN_LIGHTGRAY_COLOR.CGColor];
    [backButton.layer setCornerRadius:4];
    [self.storyInfoView addSubview:backButton];
    
    UIImage *settingsImage = [UIImage imageNamed:@"settingsButton"];
    maxButtonDim = MAX(settingsImage.size.width, settingsImage.size.height) + BUTTON_SPACING*3;
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setExclusiveTouch:YES];
    settingsButton.frame = CGRectMake(floor(self.view.frame.size.width - maxButtonDim - BUTTON_SPACING), statusBarOffset,
                                      floor(maxButtonDim), floor(maxButtonDim));
    
    [settingsButton setImage:settingsImage forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(settingsPopup:) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.showsTouchWhenHighlighted = YES;
    [settingsButton.layer setBorderWidth:0.5f];
    [settingsButton.layer setBorderColor:BANYAN_LIGHTGRAY_COLOR.CGColor];
    [settingsButton.layer setCornerRadius:4];
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
    [self.storyInfoView insertSubview:titleButton atIndex:0];
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
    self.commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.commentsButton.exclusiveTouch = YES;
    self.likesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.likesButton.exclusiveTouch = YES;
    [self.likesButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.pieceInfoView addSubview:self.authorLabel];
    [self.pieceInfoView addSubview:self.timeLabel];
    [self.pieceInfoView addSubview:self.commentsButton];
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
    self.pieceTextView.textAlignment = NSTextAlignmentJustified;
    self.pieceTextView.scrollEnabled = NO;
    [self.contentView addSubview:self.pieceTextView];

    [self refreshUI];
    
    // Do any additional setup after loading the view from its nib.
    // Update Stats
    [Piece viewedPiece:self.piece];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogInNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogOutNotification
                                               object:nil];
    
    NSLog(@"Reading piece with objectId %@ and shortText %@", REPLACE_NIL_WITH_EMPTY_STRING(self.piece.bnObjectId), REPLACE_NIL_WITH_EMPTY_STRING(self.piece.shortText));
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
    if ([self.delegate respondsToSelector:@selector(setCurrentPiece:)]) {
        [self.delegate performSelector:@selector(setCurrentPiece:) withObject:self.piece];
    }
    
    [self addGestureRecognizerToContentView:[self.delegate dismissBackPanGestureRecognizer]];
    [self addGestureRecognizerToContentView:[self.delegate dismissAheadPanGestureRecognizer]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.audioPlayer pause];
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
            // comments button
            UIImage *commentImage = nil;
            if (hasDescription || !hasImage)
                commentImage = [UIImage imageNamed:@"commentSymbolGray"];
            else
                commentImage = [UIImage imageNamed:@"commentSymbolWhite"];
            self.commentsButton.frame = CGRectMake(CGRectGetMaxX(frame)-2*35 /*size of like and comment button */ -2*3*TEXT_INSET_SMALL /*Inset between the buttons*/,
                                                   0, 35, floor(CGRectGetHeight(self.authorLabel.frame)));
            [self.commentsButton setImage:commentImage forState:UIControlStateNormal];
            self.commentsButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
            [self.commentsButton setTitle:[NSString stringWithFormat:@"%d", [self.piece.comments count]] forState:UIControlStateNormal];
            [self.commentsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 3*TEXT_INSET_SMALL, 0, 0)];
            self.commentsButton.hidden = YES;
            // like button
            self.likesButton.frame = CGRectMake(CGRectGetMaxX(self.commentsButton.frame), 0, 35, floor(CGRectGetHeight(self.authorLabel.frame)));
            self.likesButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
            [self.likesButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 3*TEXT_INSET_SMALL, 0, 0)];
            [self.likesButton setTitleColor:BANYAN_PINK_COLOR forState:UIControlStateNormal];
            [self togglePieceLikeButtonLabel];
        }
        // date label
        self.timeLabel.text = [NSString stringWithFormat:@"%@",[[BNMisc dateTimeFormatter] stringFromDate:self.piece.createdAt]];
        self.timeLabel.textEdgeInsets = UIEdgeInsetsMake(0, TEXT_INSET_BIG, 0, TEXT_INSET_SMALL);
        self.timeLabel.font = [UIFont fontWithName:@"Roboto" size:12];
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
            self.locationLabel.font = [UIFont fontWithName:@"Roboto" size:12];
            self.locationLabel.minimumScaleFactor = 0.8;
            self.locationLabel.backgroundColor = [UIColor clearColor];
            self.locationLabel.textAlignment = NSTextAlignmentLeft;
            [self.locationLabel sizeToFit];
            frame = self.locationLabel.frame;
            frame.origin = CGPointMake(CGRectGetMaxX(self.timeLabel.frame), CGRectGetMaxY(self.authorLabel.frame));
            frame.size.height = CGRectGetHeight(self.timeLabel.frame);
            self.locationLabel.frame = frame;
        }
        [self.pieceInfoView sizeToFit];
    }
    if (hasCaption) {
        frame = [UIScreen mainScreen].bounds;
        frame = CGRectMake(0, CGRectGetMaxY(self.pieceInfoView.frame), frame.size.width, 100);
        
        CGSize maximumLabelSize = frame.size;
        maximumLabelSize.width -= 40; // adjust for the textInsets
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
            descOrigin = CGPointMake(20, CGRectGetMaxY(self.pieceCaptionView.frame));
        } else {
            descOrigin = CGPointMake(20, CGRectGetMaxY(self.pieceInfoView.frame));
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
        frame.size.width = CGRectGetWidth([UIScreen mainScreen].bounds)-2*20;
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
        [self.imageView showMedia:imageMedia withPostProcess:nil];
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
        [self.commentsButton setTitleColor:BANYAN_DARKGRAY_COLOR forState:UIControlStateNormal];
    } else {
        self.pieceCaptionView.textColor =
        self.pieceTextView.textColor = BANYAN_WHITE_COLOR;
        self.authorLabel.textColor =
        self.timeLabel.textColor = BANYAN_WHITE_COLOR;
        self.locationLabel.textColor = BANYAN_WHITE_COLOR;
        [self.commentsButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
    }
    
    [self.contributorsButton setTitle:@"Contributors" forState:UIControlStateNormal];
    [self.contributorsButton setEnabled:NO];
}

- (void) updateStoryTitle
{
    if (!self.piece.story) {
        // In case the story was deleted
        return;
    }
    
    UIButton *titleButton = [self.storyInfoView.subviews objectAtIndex:0];
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:self.piece.story.title
                                                                      attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                                   NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR}];
    NSAttributedString *pageString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\rpiece %d/%d", self.piece.pieceNumber, self.piece.story.length]
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

#pragma mark target actions for read piece buttons/gestures
# pragma mark
# pragma mark target actions

- (void)settingsPopup:(id)sender
{
    UIActionSheet *actionSheet = nil;
    if (self.piece.story.canContribute && [BanyanAppDelegate loggedIn]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:self.piece.author.userId == [BNSharedUser currentUser].userId ? @"Delete piece" : nil
                                         otherButtonTitles:@"Add a piece", @"Edit piece", @"Share", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Share", nil];
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
    NSUInteger curPieceNum = self.piece.pieceNumber;
    NSNumber *turnToPage = nil;
    if (curPieceNum != [self.piece.story.pieces count]) {
        turnToPage = [NSNumber numberWithUnsignedInteger:curPieceNum];
    } else { // This was the last piece
        turnToPage = [NSNumber numberWithUnsignedInteger:curPieceNum-1];
    }
    Story *story = self.piece.story;
    
    __weak ReadPieceViewController *wself = self;
    [Piece deletePiece:self.piece completion:^{
        if (!story.pieces.count) {
            [wself.delegate readPieceViewControllerDoneReading];
        } else {
            [wself.delegate readPieceViewControllerFlipToPiece:turnToPage];
        }
    }];
}

#pragma mark Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // DO NOTHING ON CANCEL
    }
    else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // Delete piece
        // Do this after a delay so that the action sheet can be dismissed
        [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self deletePiece:self.piece];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Add a piece"]) {
        Piece *piece = [Piece newPieceDraftForStory:self.piece.story];
        ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:piece];
        addPieceViewController.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
        [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Edit piece"]) {
        ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:self.piece];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
        //    addSceneViewController.delegate = self;
        [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share"]) {
        // Share
        [self.piece shareOnFacebook];
    }
    else {
        NSLog(@"StoryReaderController_actionSheetclickedButtonAtIndex %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
    }
}

- (void)togglePieceLikeButtonLabel
{
    UIImage *heartImage = nil;
    if (self.piece.likedByCurUser) {
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
    NSLog(@"Liked!");
    [Piece toggleLikedPiece:self.piece];
    [self togglePieceLikeButtonLabel];
    [TestFlight passCheckpoint:@"Like piece"];
}

- (void)showFocusView:(UITapGestureRecognizer *)gestureRecognizer
{
    NSURL *url = nil;
    Media *imageMedia = [Media getMediaOfType:@"gif" inMediaSet:self.piece.media];
    if (![imageMedia.localURL length] && ![imageMedia.remoteURL length])
        imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
    
    if ([imageMedia.remoteURL length])
        url = [NSURL URLWithString:imageMedia.remoteURL];
    else if ([imageMedia.localURL length])
        url = [NSURL URLWithString:imageMedia.localURL];
    
    UIImage *image = ((UIImageView*)(gestureRecognizer.view)).image;
    if (image) {
        [self.mediaFocusManager showImage:image fromView:gestureRecognizer.view];
    } else {
        [self.mediaFocusManager showImageFromURL:url fromView:gestureRecognizer.view];
    }
}

#pragma mark ModifyPieceViewControllerDelegate
- (void)modifyPieceViewController:(ModifyPieceViewController *)controller didFinishAddingPiece:(Piece *)piece
{
    [self.delegate readPieceViewControllerFlipToPiece:[NSNumber numberWithInt:piece.pieceNumber]];
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
    [self.delegate readPieceViewControllerFlipToPiece:[NSNumber numberWithUnsignedInt:piece.pieceNumber]];
}

- (void)storyOverviewControllerDeletedStory
{
    // Just return from here
    [self.delegate readPieceViewControllerDoneReading];
}

@end