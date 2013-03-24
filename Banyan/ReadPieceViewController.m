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
#import "User+Edit.h"

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


@property (strong, nonatomic) BNLocationManager *locationManager;

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
@synthesize locationManager = _locationManager;

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
        self.contentView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.infoView = [[UIView alloc] init];
        // Allocate custom parts of the view depending on what the piece contains
        if (self.piece.imageURL) {
            self.imageView = [[UIImageView alloc] init];
            [self.contentView addSubview:self.imageView];
        }
        if (self.piece.shortText) {
            self.pieceCaptionView = [[UILabel alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [self.contentView addSubview:self.pieceCaptionView];
        }
        if (self.piece.longText) {
            self.pieceTextView = [[UITextView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            self.pieceTextView.editable = NO;
            [self.contentView addSubview:self.pieceTextView];
        }
        [self.view addSubview:self.contentView];
        [self.view addSubview:self.infoView];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setWantsFullScreenLayout:YES];

    self.imageView.frame = [UIScreen mainScreen].applicationFrame;
//    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
//    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    if (self.piece.imageURL && [self.piece.imageURL rangeOfString:@"asset"].location == NSNotFound) {
        [self.imageView setImageWithURL:[NSURL URLWithString:self.piece.imageURL] placeholderImage:nil];
    } else if (self.piece.imageURL) {
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

    self.imageView.backgroundColor = BANYAN_BROWN_COLOR;
    self.pieceTextView.backgroundColor = [UIColor clearColor];
    self.pieceCaptionView.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = BANYAN_WHITE_COLOR;
    self.infoView.backgroundColor = [UIColor clearColor];
//    self.pieceTextView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
    
    self.pieceTextView.text = self.piece.longText;
    self.pieceCaptionView.text = self.piece.shortText;
    
    if (![self.piece.geocodedLocation isEqual:[NSNull null]] && self.piece.geocodedLocation)
        self.locationLabel.text = self.piece.geocodedLocation;
    // Update the scene location from the coordinates (if we were not able to get the reverse geocoded location before)
//    else if (self.scene.story.isLocationEnabled && ![self.scene.location isEqual:[NSNull null]]) {
//        self.locationManager = [[BNLocationManager alloc] initWithDelegate:self];
//        [self.locationManager getNearbyLocations:self.scene.location];
//    }

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
    
    [self refreshView];
}

- (void)locationUpdated
{
    self.locationLabel.text = self.locationManager.locationStatus;
    self.piece.geocodedLocation = self.locationManager.locationStatus;
    // TODO: This should be done at the server
    [Piece editPiece:self.piece];
}

- (void) userLoginStatusChanged
{
    [self refreshView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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

// Story specific refresh
- (void)refreshStoryView
{
    [self.contributorsButton setTitle:[self.piece.story.writeAccess objectForKey:kBNStoryPrivacyScope]
                             forState:UIControlStateNormal];

    [self.contributorsButton addTarget:self action:@selector(storyContributors) forControlEvents:UIControlEventTouchUpInside];
    self.pieceTextView.scrollEnabled = YES;
    self.pieceTextView.font = [UIFont systemFontOfSize:18];
}

// Piece specific refresh
- (void)refreshPieceView
{
    [self.contributorsButton setTitle:self.piece.author.name forState:UIControlStateNormal];
    [self.contributorsButton setEnabled:NO];
    self.pieceTextView.scrollEnabled = YES;
    self.pieceTextView.font = [UIFont systemFontOfSize:18];
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
    
    [self refreshPieceView];
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
    self.locationManager.delegate = nil;
    [self setLocationManager:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark target actions for read scene buttons
- (IBAction)storyContributors
{
    NSArray *invitedToContribute = nil;
    invitedToContribute = [[self.piece.story.writeAccess objectForKey:kBNStoryPrivacyInviteeList]
                           objectForKey:kBNStoryPrivacyInvitedFacebookFriends];
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithStyle:UITableViewStylePlain];
    invitedTableViewController.invitationType = INVITED_CONTRIBUTORS_STRING;
    invitedTableViewController.delegate = self;
    [invitedTableViewController.selectedContacts setArray:invitedToContribute];
    
    [self.navigationController pushViewController:invitedTableViewController animated:YES];
}

- (IBAction)listStories:(id)sender 
{
    [self.delegate doneWithReadPieceViewController:self];
}

- (IBAction)addPiece:(UIBarButtonItem *)sender 
{
    ModifyPieceViewController *addSceneViewController = [[ModifyPieceViewController alloc] init];
    addSceneViewController.editMode = add;
    addSceneViewController.piece = [NSEntityDescription insertNewObjectForEntityForName:kBNPieceClassKey
                                                                 inManagedObjectContext:BANYAN_USER_CONTENT_MANAGED_OBJECT_CONTEXT];
    addSceneViewController.piece.story = (Story *)[BANYAN_USER_CONTENT_MANAGED_OBJECT_CONTEXT objectWithID:self.piece.story.objectID];
    addSceneViewController.delegate = self;
    [addSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [addSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:addSceneViewController animated:YES completion:nil];
}
- (IBAction)editPiece:(UIBarButtonItem *)sender 
{
    ModifyPieceViewController *editSceneViewController = [[ModifyPieceViewController alloc] init];
    editSceneViewController.editMode = edit;
    editSceneViewController.piece = self.piece;
    editSceneViewController.delegate = self;
    [editSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [editSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:editSceneViewController animated:YES completion:nil];
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
    if (!self.piece.story.initialized) {
        NSLog(@"%s Can't share yet as story with title %@ is not initialized", __PRETTY_FUNCTION__, self.piece.story.title);
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
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:self.piece.story.storyId forKey:@"object_id"];
    [[AFBanyanAPIClient sharedClient] getPath:BANYAN_API_GET_OBJECT_LINK_URL()
                                   parameters:params
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *response = (NSDictionary *)responseObject;
                                          [PFFacebookUtils reauthorizeUser:[PFUser currentUser]
                                                    withPublishPermissions:[NSArray arrayWithObject:@"publish_stream"]
                                                                  audience:PF_FBSessionDefaultAudienceFriends
                                                                     block:^(BOOL succeeded, NSError *error) {
                                                                         if (!succeeded) {
                                                                             NSLog(@"Error in getting permissions to publish");
                                                                         }
                                                                     }];
                                          [PF_FBNativeDialogs presentShareDialogModallyFrom:self
                                                                                initialText:self.piece.story.title
                                                                                      image:self.imageView.image
                                                                                        url:[NSURL URLWithString:[response objectForKey:@"link"]]
                                                                                    handler:nil];
                                          
                                          [TestFlight passCheckpoint:@"Story shared"];
                                      }
                                      failure:AF_BANYAN_ERROR_BLOCK()];
}


#pragma mark ModifyPieceViewControllerDelegate
- (void) modifyPieceViewController:(ModifyPieceViewController *)controller
             didFinishEditingPiece:(Piece *)piece
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"ReadSceneViewController_Editing scene");
}

- (void) modifyPieceViewController:(ModifyPieceViewController *)controller
              didFinishAddingPiece:(Piece *)piece
{
    NSLog(@"ReadSceneViewController_Adding scene");
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate readPieceViewControllerAddedNewPiece:self];
    }];
}

- (void) modifyPieceViewControllerDidCancel:(ModifyPieceViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) modifyPieceViewControllerDeletedPiece:(ModifyPieceViewController *)controller
{
    NSLog(@"ReadSceneViewController_Deleting scene");
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate readPieceViewControllerDeletedPiece:self];
    }];
}

- (void) modifyPieceViewControllerDeletedStory:(ModifyPieceViewController *)controller
{
    NSLog(@"ReadSceneViewController_Deleting story");
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate readPieceViewControllerDeletedStory:self];
    }];
}

# pragma mark InvitedTableViewControllerDelegate
- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController 
                   finishedInviting:(NSString *)invitingType 
                       withContacts:(NSArray *)contactsList
{
    NSMutableDictionary *readWriteAccess = nil;
    NSMutableArray *invitedList = [NSMutableArray arrayWithArray:contactsList];
    User *currentUser = [User currentUser];
    if (currentUser) {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        currentUser.name, @"name",
                                        currentUser.facebookId, @"id", nil];
        [invitedList addObject:selfInvitation];
    }
    
    [readWriteAccess setObject:kBNStoryPrivacyScopeInvited forKey:kBNStoryPrivacyScope];
    [readWriteAccess setObject:[NSDictionary dictionaryWithObject:invitedList forKey:kBNStoryPrivacyInvitedFacebookFriends]
                        forKey:kBNStoryPrivacyInviteeList];
    
    if ([invitingType isEqualToString:INVITED_CONTRIBUTORS_STRING])
    {
        self.piece.story.writeAccess = readWriteAccess;
    }
    else if ([invitingType isEqualToString:INVITED_VIEWERS_STRING]) 
    {
        self.piece.story.readAccess = readWriteAccess;
    }
    [Story editStory:self.piece.story];
    [self.navigationController popViewControllerAnimated:YES];
    [self refreshView];
}

- (void) invitedTableViewControllerDidCancel:(InvitedTableViewController *)invitedTableViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end
