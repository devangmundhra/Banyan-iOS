//
//  ReadSceneViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReadSceneViewController.h"
#import "UIImageView+AFNetworking.h"
#import "Piece+Stats.h"
#import "Story+Stats.h"
#import <QuartzCore/QuartzCore.h>
#import "AFBanyanAPIClient.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Piece+Edit.h"
#import "User+Edit.h"

@interface ReadSceneViewController ()
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *sceneTextView;
@property (weak, nonatomic) IBOutlet UILabel *storyTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UIButton *contributorsButton;
@property (weak, nonatomic) IBOutlet UILabel *viewsLabel;
@property (weak, nonatomic) IBOutlet UILabel *likesLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;


@property (strong, nonatomic) BNLocationManager *locationManager;

@end

@implementation ReadSceneViewController
@synthesize contentView = _contentView;
@synthesize imageView = _imageView;
@synthesize sceneTextView = _sceneTextView;
@synthesize storyTitleLabel = _storyTitleLabel;
@synthesize infoView = _infoView;
@synthesize contributorsButton = _contributorsButton;
@synthesize viewsLabel = _viewsLabel;
@synthesize likesLabel = _likesLabel;
@synthesize timeLabel = _timeLabel;
@synthesize locationLabel = _locationLabel;
@synthesize piece = _scene;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setWantsFullScreenLayout:YES];

    self.imageView.frame = [[UIScreen mainScreen] bounds];
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

    self.sceneTextView.backgroundColor = [UIColor clearColor];
    self.storyTitleLabel.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.infoView.backgroundColor = [UIColor clearColor];
//    self.sceneTextView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
    
    self.sceneTextView.text = self.piece.text;
    self.storyTitleLabel.text = self.piece.story.title;
    
    if (![self.piece.geocodedLocation isEqual:[NSNull null]] && self.piece.geocodedLocation)
        self.locationLabel.text = self.piece.geocodedLocation;
    // Update the scene location from the coordinates (if we were not able to get the reverse geocoded location before)
//    else if (self.scene.story.isLocationEnabled && ![self.scene.location isEqual:[NSNull null]]) {
//        self.locationManager = [[BNLocationManager alloc] initWithDelegate:self];
//        [self.locationManager getNearbyLocations:self.scene.location];
//    }

    if (self.piece.imageURL) {
        self.sceneTextView.textColor = self.storyTitleLabel.textColor = [UIColor whiteColor];
        self.contributorsButton.titleLabel.textColor = 
        self.viewsLabel.textColor = 
        self.likesLabel.textColor = 
        self.timeLabel.textColor = [UIColor whiteColor];
    }
    else {
        self.sceneTextView.textColor = self.storyTitleLabel.textColor = [UIColor blackColor];
        self.contributorsButton.titleLabel.textColor = 
        self.viewsLabel.textColor = 
        self.likesLabel.textColor = 
        self.timeLabel.textColor = [UIColor blackColor];
    }
    self.sceneTextView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.sceneTextView.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    self.sceneTextView.layer.shadowOpacity = 1.0;
    self.sceneTextView.layer.shadowRadius = 0.3;
    
    if ([self.delegate readSceneControllerEditMode]) {
        self.storyTitleLabel.alpha = 0;
        self.infoView.alpha = 1;
    }
    else {
        self.storyTitleLabel.alpha = 1;
        self.infoView.alpha = 0;
    }
    
    [self refreshView];

    [[UIApplication sharedApplication] setStatusBarHidden:![self.delegate readSceneControllerEditMode]
                                            withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:![self.delegate readSceneControllerEditMode] 
                                             animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
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
    if ([self.piece.text length] > MAX_CHAR_IN_PIECE) {
        self.sceneTextView.scrollEnabled = YES;
        self.sceneTextView.font = [UIFont systemFontOfSize:18];
    }
    else {
        self.sceneTextView.scrollEnabled = NO;
        self.sceneTextView.font = [UIFont fontWithName:STORY_FONT size:24];
    }
}

// Piece specific refresh
- (void)refreshPieceView
{
    [self.contributorsButton setTitle:self.piece.author.name forState:UIControlStateNormal];
    [self.contributorsButton setEnabled:NO];
    if ([self.piece.text length] > MAX_CHAR_IN_PIECE) {
        self.sceneTextView.scrollEnabled = YES;
        self.sceneTextView.font = [UIFont systemFontOfSize:18];
    }
    else {
        self.sceneTextView.scrollEnabled = NO;
        self.sceneTextView.font = [UIFont fontWithName:PIECE_FONT size:24];
    }
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
    [self setSceneTextView:nil];
    [self setStoryTitleLabel:nil];
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
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] 
                                                              initWithSearchBarAndNavigationControllerForInvitationType:INVITED_CONTRIBUTORS_STRING 
                                                              delegate:self 
                                                              selectedContacts:invitedToContribute];
    
    [self.navigationController pushViewController:invitedTableViewController animated:YES];
}

- (IBAction)listStories:(id)sender 
{
    [self.delegate doneWithReadSceneViewController:self];
}

- (IBAction)addPiece:(UIBarButtonItem *)sender 
{
    ModifySceneViewController *addSceneViewController = [[ModifySceneViewController alloc] init];
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
    ModifySceneViewController *editSceneViewController = [[ModifySceneViewController alloc] init];
    editSceneViewController.editMode = edit;
    editSceneViewController.piece = self.piece;
    editSceneViewController.delegate = self;
    [editSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [editSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:editSceneViewController animated:YES completion:nil];
}

- (IBAction)togglePieceTextDisplay:(UIBarButtonItem *)sender 
{
    self.sceneTextView.hidden = self.sceneTextView.hidden ? NO : YES;
    self.storyTitleLabel.hidden = self.storyTitleLabel.hidden ? NO : YES;
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

- (IBAction)tap:(UITapGestureRecognizer *)sender 
{
    [self.delegate setReadSceneControllerEditMode:(![self.delegate readSceneControllerEditMode])];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    self.storyTitleLabel.alpha = [self.delegate readSceneControllerEditMode] ? 0 : 1;
    self.infoView.alpha = [self.delegate readSceneControllerEditMode] ? 1 : 0;
    [UIView commitAnimations];
    
    [[UIApplication sharedApplication] setStatusBarHidden:![self.delegate readSceneControllerEditMode] 
                                            withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:![self.delegate readSceneControllerEditMode] animated:YES];
    [self.navigationController setToolbarHidden:![self.delegate readSceneControllerEditMode] animated:YES];
}

//#pragma mark UIGestureRecognizerDelegate
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    if ([touch.view isKindOfClass:[UIButton class]]) {
//        return NO;
//    }
//    else {
//        return YES;
//    }
//}

#pragma mark ModifySceneViewControllerDelegate
- (void) modifySceneViewController:(ModifySceneViewController *)controller
             didFinishEditingScene:(Piece *)piece
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:![self.delegate readSceneControllerEditMode] 
                                                withAnimation:UIStatusBarAnimationNone];
        [self.navigationController setNavigationBarHidden:![self.delegate readSceneControllerEditMode] animated:NO];

    }];
    NSLog(@"ReadSceneViewController_Editing scene");
}

- (void) modifySceneViewController:(ModifySceneViewController *)controller
              didFinishAddingScene:(Piece *)piece
{
    NSLog(@"ReadSceneViewController_Adding scene");
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate readSceneViewControllerAddedNewScene:self];
    }];
}

- (void) modifySceneViewControllerDidCancel:(ModifySceneViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:![self.delegate readSceneControllerEditMode] 
                                                withAnimation:UIStatusBarAnimationNone];
        [self.navigationController setNavigationBarHidden:![self.delegate readSceneControllerEditMode] animated:NO];
    }];
}

- (void) modifySceneViewControllerDeletedScene:(ModifySceneViewController *)controller
{
    NSLog(@"ReadSceneViewController_Deleting scene");
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate readSceneViewControllerDeletedScene:self];
    }];
}

- (void) modifySceneViewControllerDeletedStory:(ModifySceneViewController *)controller 
{
    NSLog(@"ReadSceneViewController_Deleting story");
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate readSceneViewControllerDeletedStory:self];
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

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end
