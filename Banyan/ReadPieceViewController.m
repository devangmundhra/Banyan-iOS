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

@interface ReadPieceViewController ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UILabel *pieceCaptionView;
@property (strong, nonatomic) IBOutlet UITextView *pieceTextView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) IBOutlet UIView *infoView;
@property (strong, nonatomic) IBOutlet UIButton *contributorsButton;
@property (strong, nonatomic) IBOutlet UILabel *viewsLabel;
@property (strong, nonatomic) IBOutlet UILabel *likesLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UILabel *locationLabel;

@property (strong, nonatomic) SMPageControl *pageControl;


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
    [self refreshView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"View bounds: %@ frame: %@ screen: %@", NSStringFromCGRect(self.view.bounds), NSStringFromCGRect(self.view.frame), NSStringFromCGRect([UIScreen mainScreen].bounds));
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    self.infoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, INFOVIEW_HEIGHT)];

    UILabel *topStoryLabel = [[UILabel alloc] initWithFrame:self.infoView.bounds];
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
    self.contentView = [[UIView alloc] initWithFrame:frame];
    self.contentView.backgroundColor = BANYAN_WHITE_COLOR;
    frame = self.contentView.bounds;
    // Allocate custom parts of the view depending on what the piece contains
    if ([self.piece.imageURL length]) {
        self.imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.imageView];
    }
    if ([self.piece.shortText length]) {
        self.pieceCaptionView = [[UILabel alloc] initWithFrame:frame];
        self.pieceCaptionView.backgroundColor = [UIColor clearColor];
        self.pieceCaptionView.text = self.piece.shortText;
        [self.contentView addSubview:self.pieceCaptionView];
    }
    if ([self.piece.longText length]) {
        self.pieceTextView = [[UITextView alloc] initWithFrame:frame];
        self.pieceTextView.editable = NO;
        self.pieceTextView.backgroundColor = [UIColor clearColor];
        self.pieceTextView.text = self.piece.longText;
        [self.contentView addSubview:self.pieceTextView];
    }
    [self.view addSubview:self.contentView];

    if ([self.piece.imageURL length] && [self.piece.imageURL rangeOfString:@"asset"].location == NSNotFound) {
        [self.imageView setImageWithURL:[NSURL URLWithString:self.piece.imageURL] placeholderImage:nil];
    } else if ([self.piece.imageURL length]) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:self.piece.imageURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullScreenImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            [self.imageView setImage:image];
        }
                failureBlock:^(NSError *error) {
                    NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
                }
         ];
    } else {
        [self.imageView cancelImageRequestOperation];
        [self.imageView setImageWithURL:nil];
    }

    if (![self.piece.geocodedLocation isEqual:[NSNull null]] && self.piece.geocodedLocation)
        self.locationLabel.text = self.piece.geocodedLocation;
    
    if (self.piece.imageURL) {
        self.pieceTextView.textColor = [UIColor whiteColor];
        self.contributorsButton.titleLabel.textColor =
        self.viewsLabel.textColor =
        self.likesLabel.textColor =
        self.timeLabel.textColor = [UIColor whiteColor];
    }
    else {
        self.pieceTextView.textColor = [UIColor blackColor];
        self.contributorsButton.titleLabel.textColor =
        self.viewsLabel.textColor =
        self.likesLabel.textColor =
        self.timeLabel.textColor = [UIColor blackColor];
    }
    self.pieceTextView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.pieceTextView.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    self.pieceTextView.layer.shadowOpacity = 1.0;
    self.pieceTextView.layer.shadowRadius = 0.3;
    
    self.pageControl = [[SMPageControl alloc] initWithFrame:CGRectMake(100, 100, CGRectGetWidth(self.view.frame), 40)];
    self.pageControl.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMaxY(self.view.frame) - 20.0f);
    self.pageControl.numberOfPages = [self.piece.story.length integerValue];
    self.pageControl.currentPage = [self.piece.pieceNumber integerValue]-1;
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = BANYAN_BROWN_COLOR;
    self.pageControl.pageIndicatorTintColor = [BANYAN_BROWN_COLOR colorWithAlphaComponent:0.5];
    self.pageControl.backgroundColor = [UIColor clearColor];
    [self.pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.pageControl];

    [self refreshView];
    
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
}

// Part of viewDidLoad that can be called again and again whenever this view needs to be
// refreshed
- (void)refreshView
{    
    self.viewsLabel.text = [NSString stringWithFormat:@"%u views", [self.piece.numberOfViews unsignedIntValue]];
    self.likesLabel.text = [NSString stringWithFormat:@"%u likes", [self.piece.numberOfLikes unsignedIntValue]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
    
    self.timeLabel.text = [dateFormat stringFromDate:self.piece.createdAt];
    
    [self toggleSceneLikeButtonLabel];
    [self toggleSceneFollowButtonLabel];
    
    [self.contributorsButton setTitle:@"Contributors" forState:UIControlStateNormal];
    [self.contributorsButton setEnabled:NO];
    self.pieceTextView.scrollEnabled = YES;
    self.pieceTextView.font = [UIFont systemFontOfSize:18];}

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(setCurrentPiece:)]) {
        [self.delegate performSelector:@selector(setCurrentPiece:) withObject:self.piece];
    }
}

#pragma mark target actions for read scene buttons
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
    if (self.piece.liked) {
        [likeButton setTitle:@"Unlike"];
    }
    else {
        [likeButton setTitle:@"Like"];
    }
    self.likesLabel.text = [NSString stringWithFormat:@"%u likes", [self.piece.numberOfLikes unsignedIntValue]];
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
    [self refreshView];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end
