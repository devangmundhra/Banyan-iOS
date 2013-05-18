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
#import "SSLabel.h"
#import "Media.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface ReadPieceViewController ()

@property (strong, nonatomic) IBOutlet UIScrollView *contentView;
@property (strong, nonatomic) IBOutlet UIView *storyInfoView;
@property (strong, nonatomic) IBOutlet SSLabel *pieceCaptionView;
@property (strong, nonatomic) IBOutlet UITextView *pieceTextView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet BNAudioStreamingPlayer *audioPlayer;

@property (strong, nonatomic) IBOutlet UIView *pieceInfoView;
@property (strong, nonatomic) IBOutlet UIButton *contributorsButton;
@property (strong, nonatomic) IBOutlet UIButton *viewsButton;
@property (strong, nonatomic) IBOutlet UIButton *likesButton;
@property (strong, nonatomic) IBOutlet UIButton *commentsButton;
@property (strong, nonatomic) IBOutlet SSLabel *authorLabel;
@property (strong, nonatomic) IBOutlet SSLabel *timeLabel;

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
@synthesize storyInfoView = _storyInfoView;
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

#define INFOVIEW_HEIGHT 44.0f // tool bar. TODO: Find a way to do this programmatically
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    self.storyInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, INFOVIEW_HEIGHT)];
    self.storyInfoView.backgroundColor = BANYAN_BLACK_COLOR;

    UILabel *topStoryLabel = [[UILabel alloc] initWithFrame:self.storyInfoView.bounds];
    topStoryLabel.backgroundColor = [UIColor clearColor];
    topStoryLabel.text = self.piece.story.title;
    topStoryLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:18];
    topStoryLabel.textColor = BANYAN_WHITE_COLOR;
    topStoryLabel.minimumScaleFactor = 0.8;
    topStoryLabel.textAlignment = NSTextAlignmentCenter;
    [self.storyInfoView addSubview:topStoryLabel];
    [self.view addSubview:self.storyInfoView];

    CGRect frame = [UIScreen mainScreen].bounds;
    frame.size.height -= CGRectGetHeight(self.storyInfoView.bounds);
    frame.origin.y = CGRectGetMaxY(self.storyInfoView.bounds);
    self.contentView = [[UIScrollView alloc] initWithFrame:frame];
    self.contentView.backgroundColor = BANYAN_WHITE_COLOR;
    
    self.pieceInfoView = [[UIView alloc] initWithFrame:CGRectZero];
    self.authorLabel = [[SSLabel alloc] initWithFrame:CGRectZero];
    self.timeLabel = [[SSLabel alloc] initWithFrame:CGRectZero];
    self.commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.likesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.likesButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.pieceInfoView addSubview:self.authorLabel];
    [self.pieceInfoView addSubview:self.timeLabel];
    [self.pieceInfoView addSubview:self.commentsButton];
    [self.pieceInfoView addSubview:self.likesButton];
    [self.contentView addSubview:self.pieceInfoView];
    
    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    self.mediaFocusManager.backgroundColor = BANYAN_BLACK_COLOR;
    self.mediaFocusManager.doneButtonFont = [UIFont fontWithName:@"Roboto" size:18];
    
    self.pageControl = [[SMPageControl alloc] initWithFrame:CGRectMake(100, 100, CGRectGetWidth(self.view.frame), 40)];
    self.pageControl.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMaxY(self.view.frame) - 20.0f);
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

- (void)viewDidUnload
{
    [self setLocationLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self setContentView:nil];
    [self setStoryInfoView:nil];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(setCurrentPiece:)]) {
        [self.delegate performSelector:@selector(setCurrentPiece:) withObject:self.piece];
    }
}

- (void)refreshUI
{
    if ([self.pieceCaptionView superview]) {
        [self.pieceCaptionView removeFromSuperview];
    }
    self.pieceCaptionView = nil;
    if ([self.pieceTextView superview]) {
        [self.pieceTextView removeFromSuperview];
    }
    self.pieceTextView = nil;
    if ([self.imageView superview]) {
        [self.imageView removeFromSuperview];
    }
    self.imageView = nil;
    
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
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
        self.audioPlayer = [[BNAudioStreamingPlayer alloc] init];
        [self addChildViewController:self.audioPlayer];
        [self.contentView addSubview:self.audioPlayer.view];
        self.audioPlayer.view.frame = frame;
        [self.audioPlayer didMoveToParentViewController:self];
        csize.height = CGRectGetMaxY(self.audioPlayer.view.frame);
    }
    
    if (hasImage) {
        frame = [UIScreen mainScreen].bounds;
        if (hasDescription) {
            frame.size.height = frame.size.height/2;
        }
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        [self.mediaFocusManager installOnView:self.imageView];
        
        self.imageView.contentMode = hasDescription ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.imageView.backgroundColor = BANYAN_BLACK_COLOR;
        [self.contentView addSubview:self.imageView];
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
        CGSize expectedLabelSize = [self.piece.author.name sizeWithFont:[UIFont fontWithName:@"Roboto" size:16]
                                                    constrainedToSize:maximumLabelSize lineBreakMode:NSLineBreakByTruncatingTail];
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
        self.timeLabel.text = [NSString stringWithFormat:@"(%@)",[dateFormat stringFromDate:self.piece.createdAt]];
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
            self.commentsButton.frame = CGRectMake(231/*152 for author + 77 for time + 2 buffer*/, 0, 35, CGRectGetHeight(frame));
            [self.commentsButton setImage:commentImage forState:UIControlStateNormal];
            self.commentsButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
            [self.commentsButton setTitle:[NSString stringWithFormat:@"%d", [self.piece.comments count]] forState:UIControlStateNormal];
            [self.commentsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
            
            // like button
            self.likesButton.frame = CGRectMake(CGRectGetMaxX(self.commentsButton.frame)+2, 0, 35, CGRectGetHeight(frame));
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
        CGSize expectedLabelSize = [self.piece.shortText sizeWithFont:[UIFont fontWithName:@"Roboto-BoldCondensed" size:26]
                                                    constrainedToSize:maximumLabelSize];
        frame.size.height = expectedLabelSize.height;
        
        self.pieceCaptionView = [[SSLabel alloc] initWithFrame:frame];
        self.pieceCaptionView.lineBreakMode = NSLineBreakByWordWrapping;
        self.pieceCaptionView.backgroundColor = [UIColor clearColor];
        self.pieceCaptionView.font = [UIFont fontWithName:@"Roboto-BoldCondensed" size:26];
        self.pieceCaptionView.minimumScaleFactor = 0.7;
        self.pieceCaptionView.textAlignment = NSTextAlignmentLeft;
        self.pieceCaptionView.textEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
        self.pieceCaptionView.numberOfLines = 4;
        [self.contentView addSubview:self.pieceCaptionView];
        self.pieceCaptionView.text = self.piece.shortText;
        csize.height = CGRectGetMaxY(self.pieceCaptionView.frame); // overwrite because caption will always be lower than image.
    }
    if (hasDescription) {
        frame = CGRectMake(20, CGRectGetMaxY(frame), frame.size.width-2*20, [UIScreen mainScreen].applicationFrame.size.height - CGRectGetMaxY(frame));
        self.pieceTextView = [[UITextView alloc] initWithFrame:frame];
        self.pieceTextView.editable = NO;
        self.pieceTextView.backgroundColor = [UIColor clearColor];
        self.pieceTextView.font = [UIFont fontWithName:@"Roboto" size:18];
        self.pieceTextView.textAlignment = NSTextAlignmentLeft;
        self.pieceTextView.scrollEnabled = NO;
        [self.contentView addSubview:self.pieceTextView];
        self.pieceTextView.text = self.piece.longText;
        frame = self.pieceTextView.frame;
        frame.size.height = self.pieceTextView.contentSize.height;
        self.pieceTextView.frame = frame;
        csize.height += CGRectGetHeight(self.pieceTextView.frame);
    }
    [self.view addSubview:self.contentView];
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
    
    self.pageControl.numberOfPages = [self.piece.story.length integerValue];
    self.pageControl.currentPage = [self.piece.pieceNumber integerValue]-1;
    
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
    pieceObserverToken3 = [self.piece addObserverForKeyPath:@"imageURL" task:^(id obj, NSDictionary *change) {
        [readPieceViewController refreshUI];
    }];
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
- (IBAction)storyContributors
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithViewerPermissions:self.piece.story.readAccess
                                                                                                     contributorPermission:self.piece.story.writeAccess];
    invitedTableViewController.delegate = self;
    
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:invitedTableViewController] animated:YES completion:nil];
}

- (void)togglePieceLikeButtonLabel
{
    UIImage *heartImage = nil;
    if (self.piece.statistics.liked) {
        heartImage = [UIImage imageNamed:@"heartSymbolPink"];
    }
    else {
        heartImage = [UIImage imageNamed:@"heartSymbolHollow"];
    }
    [self.likesButton setImage:heartImage forState:UIControlStateNormal];
    [self.likesButton setTitle:[NSString stringWithFormat:@"%d", [self.piece.statistics.likers count]] forState:UIControlStateNormal];
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

# pragma mark InvitedTableViewControllerDelegate
- (void)invitedTableViewController:(InvitedTableViewController *)invitedTableViewController
        finishedInvitingForViewers:(NSArray *)selectedViewers
                      contributors:(NSArray *)selectedContributors
{
    NSDictionary *selfInvitation = nil;
    PFUser *currentUser = [PFUser currentUser];
    if (HAVE_ASSERTS)
        assert(currentUser);
    
    if (currentUser) {
        selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [currentUser objectForKey:USER_NAME], @"name",
                                        [currentUser objectForKey:USER_FACEBOOK_ID], @"id", nil];
    }
    // Update read access
    if (selectedViewers) {
        NSMutableDictionary *readAccess = nil;
        NSMutableArray *readList = [NSMutableArray arrayWithArray:selectedViewers];
        [readList addObjectsFromArray:selectedContributors];
        [readList addObject:selfInvitation];
        [readAccess setObject:kBNStoryPrivacyScopeInvited forKey:kBNStoryPrivacyScope];
        [readAccess setObject:[NSDictionary dictionaryWithObject:readList forKey:kBNStoryPrivacyInvitedFacebookFriends]
                       forKey:kBNStoryPrivacyInviteeList];
        self.piece.story.readAccess = readAccess;
    }
    
    // Update write access
    if (selectedContributors) {
        NSMutableDictionary *writeAccess = nil;
        NSMutableArray *writeList = [NSMutableArray arrayWithArray:selectedContributors];
        [writeList addObject:selfInvitation];
        [writeAccess setObject:kBNStoryPrivacyScopeInvited forKey:kBNStoryPrivacyScope];
        [writeAccess setObject:[NSDictionary dictionaryWithObject:writeList forKey:kBNStoryPrivacyInvitedFacebookFriends]
                       forKey:kBNStoryPrivacyInviteeList];
        self.piece.story.writeAccess = writeAccess;
    }
    
    [Story editStory:self.piece.story];
    [self refreshUI];
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
    return self.delegate.view.bounds;
}

// Returns the view controller in which the focus controller is going to be added.
// This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager
{
    return self.delegate;
}

// Returns an URL where the image is stored. This URL is used to create an image at full screen. The URL may be local (file://) or distant (http://).
- (NSURL *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaURLForView:(UIView *)view
{
    NSURL *url = nil;
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];

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
