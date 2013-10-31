//
//  ReadSceneViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReadPieceViewController.h"
#import "Piece+Stats.h"
#import "Story+Stats.h"
#import <QuartzCore/QuartzCore.h>
#import "AFBanyanAPIClient.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Piece+Edit.h"
#import "Piece+Create.h"
#import "SMPageControl.h"
#import "NSObject+BlockObservation.h"
#import "Media.h"
#import "User.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "Piece+Delete.h"
#import "ModifyStoryViewController.h"
#import "ModifyPieceViewController.h"
#import "BNLabel.h"

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

@property (strong, nonatomic) IBOutlet UILabel *locationLabel;

@property (strong, nonatomic) SMPageControl *pageControl;

@property (strong, nonatomic) AMBlockToken *pieceObserverToken1;
@property (strong, nonatomic) AMBlockToken *pieceObserverToken2;
@property (strong, nonatomic) AMBlockToken *pieceObserverToken3;
@property (strong, nonatomic) AMBlockToken *pieceObserverToken4;

@property (strong, nonatomic) ASMediaFocusManager *mediaFocusManager;
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
@synthesize pageControl = _pageControl;
@synthesize pieceObserverToken1, pieceObserverToken2, pieceObserverToken3, pieceObserverToken4;
@synthesize mediaFocusManager = _mediaFocusManager;
@synthesize audioPlayer = _audioPlayer;
@synthesize storyInfoView = _storyInfoView;

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
    }
    return self;
}

- (void) userLoginStatusChanged
{
    [self refreshUI];
}

#define INFOVIEW_HEIGHT 38.0f
#define BUTTON_SPACING 5.0f

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
    titleButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:16];
    titleButton.titleLabel.minimumScaleFactor = 0.7;
    titleButton.backgroundColor = [UIColor clearColor];
    [titleButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleButton setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.5] forState:UIControlStateNormal];
    [titleButton setTitle:self.piece.story.title forState:UIControlStateNormal];
    if (self.piece.story.canContribute) {
        titleButton.showsTouchWhenHighlighted = YES;
        [titleButton addTarget:self action:@selector(editStoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        titleButton.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.piece.story.title
                                                                                attributes:@{NSUnderlineStyleAttributeName: @1}];
    }
    [self.storyInfoView insertSubview:titleButton atIndex:0];
    
    [self.view addSubview:self.storyInfoView];
    
    frame = [UIScreen mainScreen].bounds;
    frame.origin.y += CGRectGetMaxY(self.storyInfoView.frame);
    frame.size.height -= CGRectGetMaxY(self.storyInfoView.frame);
    self.contentView = [[UIScrollView alloc] initWithFrame:frame];
    self.contentView.backgroundColor = BANYAN_WHITE_COLOR;
    [self.view addSubview:self.contentView];

    self.pieceInfoView = [[UIView alloc] initWithFrame:CGRectZero];
    self.authorLabel = [[BNLabel alloc] initWithFrame:CGRectZero];
    self.timeLabel = [[BNLabel alloc] initWithFrame:CGRectZero];
    self.commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.commentsButton.exclusiveTouch = YES;
    self.likesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.likesButton.exclusiveTouch = YES;
    [self.likesButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.pieceInfoView addSubview:self.authorLabel];
    [self.pieceInfoView addSubview:self.timeLabel];
    [self.pieceInfoView addSubview:self.commentsButton];
    [self.pieceInfoView addSubview:self.likesButton];
    [self.contentView addSubview:self.pieceInfoView];
    
    // Media focus manager
    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    self.mediaFocusManager.backgroundColor = BANYAN_BLACK_COLOR;
    self.mediaFocusManager.doneButtonFont = [UIFont fontWithName:@"Roboto" size:18];
    
    // Audip player
    self.audioPlayer = [[BNAudioStreamingPlayer alloc] init];
    [self addChildViewController:self.audioPlayer];
    [self.contentView addSubview:self.audioPlayer.view];
    [self.audioPlayer didMoveToParentViewController:self];
    
    // Image view
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.mediaFocusManager installOnView:self.imageView];
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
    self.pieceCaptionView.textEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
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
    
    // Page control
    self.pageControl = [[SMPageControl alloc] initWithFrame:CGRectMake(100, 100, CGRectGetWidth(self.view.frame), 40)];
    self.pageControl.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMaxY(self.view.frame) - 40.0f);
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = BANYAN_BROWN_COLOR;
    self.pageControl.pageIndicatorTintColor = [BANYAN_BROWN_COLOR colorWithAlphaComponent:0.5];
    self.pageControl.backgroundColor = [UIColor clearColor];
    [self.pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.pageControl];

    [self refreshUI];
    
    // Do any additional setup after loading the view from its nib.
    // Update Stats
    [Piece viewedPiece:self.piece];

    [self addPieceObserver];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogInNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogOutNotification
                                               object:nil];
}

- (void) addGestureRecognizerToContentView:(UIGestureRecognizer *)gR
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:BNUserDefaultsUserPageTurnAnimation] && [self.delegate dismissPanGestureRecognizer]) {
        [self.contentView addGestureRecognizer:gR];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(setCurrentPiece:)]) {
        [self.delegate performSelector:@selector(setCurrentPiece:) withObject:self.piece];
    }
    
    [self addGestureRecognizerToContentView:[self.delegate dismissPanGestureRecognizer]];
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
    // Add author/date/stats here
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
        CGSize maximumLabelSize = CGSizeMake(130, CGRectGetHeight(frame));
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        paraStyle.alignment = NSTextAlignmentLeft;
        CGSize expectedLabelSize = [self.piece.author.name boundingRectWithSize:maximumLabelSize options:0
                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:16],
                                                                                                                 NSParagraphStyleAttributeName: paraStyle}
                                                                 context:nil].size;

        self.authorLabel.frame = CGRectMake(0, 0, expectedLabelSize.width+22/*for inset adjustment*/, CGRectGetHeight(frame));
        self.authorLabel.textEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 2);
        self.authorLabel.text = self.piece.author.name;
        self.authorLabel.font = [UIFont fontWithName:@"Roboto" size:16];
        self.authorLabel.minimumScaleFactor = 0.8;
        self.authorLabel.backgroundColor= [UIColor clearColor];
        self.authorLabel.textAlignment = NSTextAlignmentLeft;
        
        // date label
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateStyle:NSDateFormatterShortStyle];
        self.timeLabel.frame = CGRectMake(CGRectGetMaxX(self.authorLabel.frame), 0, 75, CGRectGetHeight(frame));
        self.timeLabel.text = [NSString stringWithFormat:@"(%@)",[dateFormat stringFromDate:[self.piece.createdAt
                                                                                             dateByAddingTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT]]]];
        self.timeLabel.textEdgeInsets = UIEdgeInsetsMake(0, 2, 0, 0);
        self.timeLabel.font = [UIFont fontWithName:@"Roboto" size:16];
        self.timeLabel.minimumScaleFactor = 0.8;
        self.timeLabel.backgroundColor = [UIColor clearColor];
        self.timeLabel.textAlignment = NSTextAlignmentLeft;
        
        if ([BanyanAppDelegate loggedIn])
        {
            // comments button
            UIImage *commentImage = nil;
            if (hasDescription || !hasImage)
                commentImage = [UIImage imageNamed:@"commentSymbolGray"];
            else
                commentImage = [UIImage imageNamed:@"commentSymbolWhite"];
            self.commentsButton.frame = CGRectMake(231/*152 for author + 77 for time + 2 buffer*/, 0, 35, floor(CGRectGetHeight(frame)));
            [self.commentsButton setImage:commentImage forState:UIControlStateNormal];
            self.commentsButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
            [self.commentsButton setTitle:[NSString stringWithFormat:@"%d", [self.piece.comments count]] forState:UIControlStateNormal];
            [self.commentsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
            self.commentsButton.hidden = YES;
            // like button
            self.likesButton.frame = CGRectMake(floor(CGRectGetMaxX(self.commentsButton.frame)+2), 0, 35, floor(CGRectGetHeight(frame)));
            self.likesButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
            [self.likesButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
            [self.likesButton setTitleColor:BANYAN_PINK_COLOR forState:UIControlStateNormal];
            [self togglePieceLikeButtonLabel];
        }
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
        CGPoint descOrigin = CGPointMake(20, CGRectGetMaxY(frame));
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.alignment = NSTextAlignmentLeft;
        
        frame = [self.piece.longText boundingRectWithSize:CGSizeMake(frame.size.width-2*20, FLT_MAX)
                                                  options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:18],
                                                            NSParagraphStyleAttributeName: paraStyle}
                                                  context:nil];
        frame.origin = descOrigin;
        frame.size.height += CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]); // Some correction otherwise the whole text isn't showing up
        
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
        if ([imageMedia.remoteURL length]) {
            [self.imageView setImageWithURL:[NSURL URLWithString:imageMedia.remoteURL] placeholderImage:nil options:SDWebImageProgressiveDownload];
        } else {
            ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
            [library assetForURL:[NSURL URLWithString:imageMedia.localURL] resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                CGImageRef imageRef = [rep fullScreenImage];
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                [self.imageView setImage:image];
            }
                    failureBlock:^(NSError *error) {
                        NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
                    }
             ];
        }
    } else {
        [self.imageView setImageWithURL:nil];
    }
    
    if (hasDescription || !hasImage) {
        self.pieceCaptionView.textColor =
        self.pieceTextView.textColor = BANYAN_BLACK_COLOR;
        self.authorLabel.textColor =
        self.timeLabel.textColor = BANYAN_DARKGRAY_COLOR;
        [self.commentsButton setTitleColor:BANYAN_DARKGRAY_COLOR forState:UIControlStateNormal];
    } else {
        self.pieceCaptionView.textColor =
        self.pieceTextView.textColor = BANYAN_WHITE_COLOR;
        self.authorLabel.textColor =
        self.timeLabel.textColor = BANYAN_WHITE_COLOR;
        [self.commentsButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
    }
    
    if ([self.piece.location.name length])
        self.locationLabel.text = self.piece.location.name;
    
    self.pageControl.numberOfPages = self.piece.story.length;
    self.pageControl.currentPage = self.piece.pieceNumber-1;
    
    [self.contributorsButton setTitle:@"Contributors" forState:UIControlStateNormal];
    [self.contributorsButton setEnabled:NO];
}

#pragma mark notifications
- (void)addPieceObserver
{
    __weak ReadPieceViewController *readPieceViewController = self;
    pieceObserverToken1 = [self.piece addObserverForKeyPath:@"shortText" task:^(id obj, NSDictionary *change) {
        [readPieceViewController refreshUI];
    }];
    pieceObserverToken2 = [self.piece addObserverForKeyPath:@"longText" task:^(id obj, NSDictionary *change) {
        [readPieceViewController refreshUI];
    }];
    pieceObserverToken3 = [self.piece addObserverForKeyPath:@"media" task:^(id obj, NSDictionary *change) {
        [readPieceViewController refreshUI];
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self setLocationLabel:nil];
    [self setContentView:nil];
    [self setPieceInfoView:nil];
    [self setImageView:nil];
    [self setPieceTextView:nil];
    [self setPieceCaptionView:nil];
    [self setViewsButton:nil];
    [self setLikesButton:nil];
    [self setCommentsButton:nil];
    [self setAuthorLabel:nil];
    [self setTimeLabel:nil];
    [self setContributorsButton:nil];
    [self setPageControl:nil];
    [self removePieceObserver];
    [self setMediaFocusManager:nil];
    [self setAudioPlayer:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removePieceObserver
{
    if (pieceObserverToken1) {
        [self.piece removeObserverWithBlockToken:pieceObserverToken1];
        pieceObserverToken1 = nil;
    }
    if (pieceObserverToken2) {
        [self.piece removeObserverWithBlockToken:pieceObserverToken2];
        pieceObserverToken2 = nil;
    }
    if (pieceObserverToken3) {
        [self.piece removeObserverWithBlockToken:pieceObserverToken3];
        pieceObserverToken3 = nil;
    }
    if (pieceObserverToken4) {
        [self.piece removeObserverWithBlockToken:pieceObserverToken4];
        pieceObserverToken4 = nil;
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
                                         otherButtonTitles:@"Add a piece", @"Edit piece", @"Share via Facebook", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Share via Facebook", nil];
    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.contentView];
}

- (void)editStoryButtonPressed:(id)sender
{
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    ModifyStoryViewController *newStoryViewController = [[ModifyStoryViewController alloc] initWithStory:self.piece.story];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newStoryViewController];
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
    [Piece deletePiece:self.piece];
    
    if (!self.piece.story.pieces.count) {
        [self.delegate readPieceViewControllerDoneReading];
    } else {
        [self.delegate readPieceViewControllerFlipToPiece:turnToPage];
    }
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
        [self performSelector:@selector(deletePiece:) withObject:self.piece afterDelay:0.5];
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
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share via Facebook"]) {
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


- (IBAction)share:(UIBarButtonItem *)sender 
{    
    if (self.piece.story.remoteStatus != RemoteObjectStatusSync) {
        NSLog(@"%s Can't share yet as story with title %@ is not sync'ed", __PRETTY_FUNCTION__, self.piece.story.title);
        return;
    }
    
    [[FBSession activeSession] requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_stream"]
                                            defaultAudience:FBSessionDefaultAudienceFriends
                                          completionHandler:^(FBSession *session, NSError *error) {
                                              if (error) {
                                                  NSLog(@"Error %@ in getting permissions to publish", [error localizedDescription]);
                                              }
                                          }];
    [FBDialogs presentOSIntegratedShareDialogModallyFrom:self
                                             initialText:self.piece.story.title
                                                   image:self.imageView.image
                                                     url:[NSURL URLWithString:self.piece.permaLink]
                                                 handler:nil];
    
    [TestFlight passCheckpoint:@"Piece shared"];
}

#pragma mark UIPageControl
- (IBAction)changePage:(id)sender
{
    NSInteger page = self.pageControl.currentPage;
    if ([self.delegate respondsToSelector:@selector(readPieceViewControllerFlipToPiece:)]) {
        [self.delegate performSelector:@selector(readPieceViewControllerFlipToPiece:) withObject:[NSNumber numberWithInteger:page+1]];
    }
}

#pragma mark ModifyPieceViewControllerDelegate
- (void)modifyPieceViewController:(ModifyPieceViewController *)controller didFinishAddingPiece:(Piece *)piece
{
    [self.delegate readPieceViewControllerFlipToPiece:[NSNumber numberWithInt:piece.pieceNumber]];
}

#pragma mark - ASMediaFocusDelegate
// Returns an image that represents the media view. This image is used in the focusing animation view.
// It is usually a small image.
- (UIImage *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager imageForView:(UIView *)view
{
    return ((UIImageView *)view).image;
}

// Returns the final focused frame for this media view. This frame is usually a full screen frame.
- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager finalFrameforView:(UIView *)view
{
    return self.view.bounds;
}

// Returns the view controller in which the focus controller is going to be added.
// This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager
{
    return self;
}

// Returns an URL where the image is stored. This URL is used to create an image at full screen. The URL may be local (file://) or distant (http://).
- (NSURL *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaURLForView:(UIView *)view
{
    NSURL *url = nil;
    Media *imageMedia = [Media getMediaOfType:@"gif" inMediaSet:self.piece.media];
    if (![imageMedia.localURL length] && ![imageMedia.remoteURL length])
        imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
    
    if ([imageMedia.remoteURL length])
        url = [NSURL URLWithString:imageMedia.remoteURL];
    else if ([imageMedia.localURL length])
        url = [NSURL URLWithString:imageMedia.localURL];
    
    return url;
}

// Returns the title for this media view. Return nil if you don't want any title to appear.
- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager titleForView:(UIView *)view
{
    return nil;
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end
