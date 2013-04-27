//
//  ReadSceneViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReadPieceViewController.h"
#import "UIImageView+AFNetworking.h"
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

@interface ReadPieceViewController ()

@property (strong, nonatomic) IBOutlet UIScrollView *contentView;
@property (strong, nonatomic) IBOutlet SSLabel *pieceCaptionView;
@property (strong, nonatomic) IBOutlet UITextView *pieceTextView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) IBOutlet UIView *infoView;
@property (strong, nonatomic) IBOutlet UIButton *contributorsButton;
@property (strong, nonatomic) IBOutlet UILabel *viewsLabel;
@property (strong, nonatomic) IBOutlet UILabel *likesLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UILabel *locationLabel;

@property (strong, nonatomic) SMPageControl *pageControl;

@property (strong, nonatomic) AMBlockToken *pieceObserverToken1;
@property (strong, nonatomic) AMBlockToken *pieceObserverToken2;
@property (strong, nonatomic) AMBlockToken *pieceObserverToken3;
@property (strong, nonatomic) AMBlockToken *pieceObserverToken4;


@end

@implementation ReadPieceViewController
@synthesize contentView = _contentView;
@synthesize imageView = _imageView;
@synthesize pieceCaptionView = _pieceCaptionView;
@synthesize pieceTextView = _pieceTextView;
@synthesize infoView = _infoView;
@synthesize contributorsButton = _contributorsButton;
@synthesize viewsLabel = _viewsLabel;
@synthesize likesLabel = _likesLabel;
@synthesize timeLabel = _timeLabel;
@synthesize locationLabel = _locationLabel;
@synthesize piece = _piece;
@synthesize delegate = _delegate;
@synthesize pageControl = _pageControl;
@synthesize pieceObserverToken1, pieceObserverToken2, pieceObserverToken3, pieceObserverToken4;

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

#define INFOVIEW_HEIGHT 64.0f // Status bar + tool bar. TODO: Find a way to do this programmatically
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
    self.view.backgroundColor = BANYAN_BLACK_COLOR;
    
    self.infoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, INFOVIEW_HEIGHT)];
    self.infoView.backgroundColor = [UIColor clearColor];

    UILabel *topStoryLabel = [[UILabel alloc] initWithFrame:self.infoView.bounds];
    topStoryLabel.backgroundColor = [UIColor clearColor];
    topStoryLabel.text = self.piece.story.title;
    topStoryLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:18];
    topStoryLabel.textColor = [UIColor grayColor];
    topStoryLabel.minimumFontSize = 14;
    topStoryLabel.textAlignment = NSTextAlignmentCenter;
    [self.infoView addSubview:topStoryLabel];
    [self.view addSubview:self.infoView];

    CGRect frame = self.view.bounds;
    frame.size.height -= CGRectGetHeight(self.infoView.bounds);
    frame.origin.y += CGRectGetHeight(self.infoView.bounds);
    self.contentView = [[UIScrollView alloc] initWithFrame:frame];
    self.contentView.backgroundColor = BANYAN_BLACK_COLOR;
    
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
    [self setInfoView:nil];
    [self setImageView:nil];
    [self setPieceTextView:nil];
    [self setPieceCaptionView:nil];
    [self setViewsLabel:nil];
    [self setLikesLabel:nil];
    [self setTimeLabel:nil];
    [self setContributorsButton:nil];
    [self setPageControl:nil];
    [self removePieceObserver];
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
    
    // Allocate custom parts of the view depending on what the piece contains
    BOOL hasImage = [self.piece.media.localURL length] || [self.piece.media.remoteURL length];
    BOOL hasCaption = [self.piece.shortText length];
    BOOL hasDescription = [self.piece.longText length];
    
    // If there is no long text full screen image, else image size of half size
    // If there is an image and no long text, caption is at the bottom
    // If there is no image or long text, caption in the middle
    // Long text always below caption
    CGRect frame;
    CGSize csize = self.contentView.contentSize;
    csize.height = 0;
    
    if (hasImage) {
        frame = [UIScreen mainScreen].bounds;
        if (hasDescription) {
            frame.origin.y += 20.0f;
            frame.size.height = frame.size.height/2;
            frame.origin.x = 20.0f; // 20f offset
            frame.size.width -= 2*20.0f;
        }
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        self.imageView.contentMode = hasDescription ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.imageView];
        csize.height = CGRectGetMaxY(self.imageView.frame);
    }
    if (hasCaption) {
        frame = [UIScreen mainScreen].bounds;
        if (hasImage) {
            if (hasDescription) {
                
            } else {
                
            }
        } else {
            CGRectMake(0, 0, frame.size.width, 0.5*frame.size.height);
        }
        if (hasImage && !hasDescription) {
            frame = CGRectMake(0, 0.5*frame.size.height, frame.size.width, 0.5*frame.size.height);
        } else {
            frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame), frame.size.width, 0.5*frame.size.height);
        }
        CGSize maximumLabelSize = frame.size;
        CGSize expectedLabelSize = [self.piece.shortText sizeWithFont:[UIFont fontWithName:@"Roboto-BoldCondensed" size:26]
                                                    constrainedToSize:maximumLabelSize lineBreakMode:NSLineBreakByTruncatingTail];
        frame.size.height = expectedLabelSize.height;
        
        self.pieceCaptionView = [[SSLabel alloc] initWithFrame:frame];
        self.pieceCaptionView.backgroundColor = [UIColor clearColor];
        self.pieceCaptionView.font = [UIFont fontWithName:@"Roboto-BoldCondensed" size:26];
        self.pieceCaptionView.minimumFontSize = 20;
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
    [self.contentView sizeToFit];
    [self.view addSubview:self.contentView];
    self.contentView.contentSize = csize;
    [self.contentView setContentOffset:CGPointMake(0,0)];
    
    if (hasImage) {        
        if ([self.piece.media.remoteURL length]) {
            [self.imageView setImageWithURL:[NSURL URLWithString:self.piece.media.remoteURL] placeholderImage:nil];
        } else {
            ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
            [library assetForURL:[NSURL URLWithString:self.piece.media.localURL] resultBlock:^(ALAsset *asset) {
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
        [self.imageView cancelImageRequestOperation];
        [self.imageView setImageWithURL:nil];
    }
    
    self.pieceCaptionView.textColor =
    self.pieceTextView.textColor =
    self.contributorsButton.titleLabel.textColor =
    self.viewsLabel.textColor =
    self.likesLabel.textColor =
    self.timeLabel.textColor = BANYAN_WHITE_COLOR;
    
    if ([self.piece.location.name length])
        self.locationLabel.text = self.piece.location.name;
    
    self.viewsLabel.text = [NSString stringWithFormat:@"%u views", [self.piece.statistics.numberOfViews unsignedIntValue]];
    self.likesLabel.text = [NSString stringWithFormat:@"%u likes", [self.piece.statistics.numberOfLikes unsignedIntValue]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
    
    self.timeLabel.text = [dateFormat stringFromDate:self.piece.createdAt];
    
    self.pageControl.numberOfPages = [self.piece.story.length integerValue];
    self.pageControl.currentPage = [self.piece.pieceNumber integerValue]-1;

    [self toggleSceneLikeButtonLabel];
    [self toggleSceneFollowButtonLabel];
    
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

#pragma mark target actions for read piece buttons
- (IBAction)storyContributors
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithViewerPermissions:self.piece.story.readAccess
                                                                                                     contributorPermission:self.piece.story.writeAccess];
    invitedTableViewController.delegate = self;
    
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:invitedTableViewController] animated:YES completion:nil];
}

- (void)toggleSceneLikeButtonLabel
{
    UIBarButtonItem *likeButton = (UIBarButtonItem *)[self.navigationController.toolbar.items objectAtIndex:0];
    if (self.piece.statistics.liked) {
        [likeButton setTitle:@"Unlike"];
    }
    else {
        [likeButton setTitle:@"Like"];
    }
    self.likesLabel.text = [NSString stringWithFormat:@"%u likes", [self.piece.statistics.numberOfLikes unsignedIntValue]];
}

- (void)toggleSceneFollowButtonLabel
{
//    if (self.scene.favourite)
//        [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
//    else {
//        [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
//    }
}

- (IBAction)like:(UIBarButtonItem *)sender
{
    NSLog(@"Liked!");
    [Piece toggleLikedPiece:self.piece];
    [self toggleSceneLikeButtonLabel];
    [TestFlight passCheckpoint:@"Like scene"];
}


- (IBAction)follow:(UIBarButtonItem *)sender
{
    NSLog(@"Following!");
    [Piece toggleFavouritedPiece:self.piece];
    [self toggleSceneFollowButtonLabel];
    
    [TestFlight passCheckpoint:@"Follow scene"];
}

- (IBAction)share:(UIBarButtonItem *)sender 
{    
    if (self.piece.story.remoteStatus != RemoteObjectStatusSync) {
        NSLog(@"%s Can't share yet as story with title %@ is not sync'ed", __PRETTY_FUNCTION__, self.piece.story.title);
        return;
    }
    
    if (![[AFBanyanAPIClient sharedClient] isReachable]) {
        NSLog(@"%s Can't connect to internet", __PRETTY_FUNCTION__);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network unavailable"
                                                            message:@"Cannot share the story since network is unavailable."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:self.piece.story.bnObjectId forKey:@"object_id"];
    [[AFBanyanAPIClient sharedClient] getPath:BANYAN_API_GET_OBJECT_LINK_URL()
                                   parameters:params
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *response = (NSDictionary *)responseObject;
                                          [PFFacebookUtils reauthorizeUser:[PFUser currentUser]
                                                    withPublishPermissions:[NSArray arrayWithObject:@"publish_stream"]
                                                                  audience:FBSessionDefaultAudienceFriends
                                                                     block:^(BOOL succeeded, NSError *error) {
                                                                         if (!succeeded) {
                                                                             NSLog(@"Error in getting permissions to publish");
                                                                         }
                                                                     }];
                                          [FBNativeDialogs presentShareDialogModallyFrom:self
                                                                                initialText:self.piece.story.title
                                                                                      image:self.imageView.image
                                                                                        url:[NSURL URLWithString:[response objectForKey:@"link"]]
                                                                                    handler:nil];
                                          
                                          [TestFlight passCheckpoint:@"Story shared"];
                                      }
                                      failure:AF_BANYAN_ERROR_BLOCK()];
}

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

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end
