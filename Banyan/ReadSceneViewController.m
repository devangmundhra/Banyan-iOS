//
//  ReadSceneViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReadSceneViewController.h"
#import "UIImageView+AFNetworking.h"
#import "Scene+Stats.h"
#import "Story+Stats.h"
#import <QuartzCore/QuartzCore.h>
#import "ParseAPIEngine.h"

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

@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (weak, nonatomic) UserManagementModule *userManagementModule;

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
@synthesize actionView = _actionView;
@synthesize likeButton = _likeButton;
@synthesize followButton = _followButton;
@synthesize shareButton = _shareButton;
@synthesize locationLabel = _locationLabel;
@synthesize userManagementModule = _userManagementModule;
@synthesize scene = _scene;
@synthesize delegate = _delegate;
@synthesize locationManager = _locationManager;

- (UserManagementModule *)userManagementModule
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.userManagementModule.owningViewController = self;
    
    return delegate.userManagementModule;
}

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
    if (self.scene.imageURL && [self.scene.imageURL rangeOfString:@"asset"].location == NSNotFound) {
        [self.imageView setImageWithURL:[NSURL URLWithString:self.scene.imageURL] placeholderImage:self.scene.image];
    } else if (self.scene.imageURL) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:self.scene.imageURL] resultBlock:^(ALAsset *asset) {
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
    
    self.shareButton.hidden = YES;
    
    self.sceneTextView.backgroundColor = [UIColor clearColor];
    self.storyTitleLabel.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.infoView.backgroundColor = [UIColor clearColor];
    self.actionView.backgroundColor = [UIColor clearColor];
    
    self.sceneTextView.text = self.scene.text;
    self.storyTitleLabel.text = self.scene.story.title;
    
    if (![self.scene.geocodedLocation isEqual:[NSNull null]] && self.scene.geocodedLocation)
        self.locationLabel.text = self.scene.geocodedLocation;
    else if (self.scene.story.isLocationEnabled && ![self.scene.location isEqual:[NSNull null]]) {
        self.locationManager = [[BNLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager reverseGeoCodedLocation:self.scene.location];
    }

    if (self.scene.image || self.scene.imageURL) {
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
        self.actionView.alpha = 1;
        self.infoView.alpha = 1;
    }
    else {
        self.storyTitleLabel.alpha = 1;
        self.actionView.alpha = 0;
        self.infoView.alpha = 0;
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:![self.delegate readSceneControllerEditMode] 
                                            withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:![self.delegate readSceneControllerEditMode] 
                                             animated:NO];
}

- (void)locationUpdated
{
    self.locationLabel.text = self.locationManager.locationStatus;
    self.scene.geocodedLocation = self.locationManager.locationStatus;
    // TODO: This should be done at the server
    // Edit this scene with the geolocated data
    BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene
                                                                    tempId:self.scene.sceneId
                                                                   storyId:self.scene.story.storyId];
    BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionEdit dependencies:nil];
    op.action.context = [NSDictionary dictionaryWithObject:self.scene.geocodedLocation forKey:SCENE_GEOCODEDLOCATION];
    ADD_OPERATION_TO_QUEUE(op);
    
    if (self.scene.previousScene == nil) {
        self.scene.story.geocodedLocation = self.scene.geocodedLocation;
        obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeStory
                                                     tempId:self.scene.story.storyId
                                                    storyId:self.scene.story.storyId];
        op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionEdit dependencies:nil];
        op.action.context = [NSDictionary dictionaryWithObject:self.scene.story.geocodedLocation forKey:STORY_GEOCODEDLOCATION];
        ADD_OPERATION_TO_QUEUE(op);
    }
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
    [Scene viewedScene:self.scene];
    [self refreshView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:USER_MANAGEMENT_MODULE_USER_LOGIN_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:USER_MANAGEMENT_MODULE_USER_LOGOUT_NOTIFICATION 
                                               object:nil];
}

// Story specific refresh
- (void)refreshStoryView
{
    if (self.scene.story.publicContributors) {
        [self.contributorsButton setTitle:@"Public"
                                 forState:UIControlStateNormal];
    }
    else {
        [self.contributorsButton setTitle:[NSString stringWithFormat:@"%u contributors invited",
                                           [self.scene.story.invitedToContribute count]] 
                                 forState:UIControlStateNormal];
    }
    [self.contributorsButton addTarget:self action:@selector(storyContributors) forControlEvents:UIControlEventTouchUpInside];
    self.sceneTextView.font = [UIFont fontWithName:STORY_FONT size:24];
}

// Scene specific refresh
- (void)refreshSceneView
{
    [self.contributorsButton setTitle:self.scene.author.name forState:UIControlStateNormal];
    [self.contributorsButton setEnabled:NO];
    self.sceneTextView.font = [UIFont fontWithName:SCENE_FONT size:24];
}

// Part of viewDidLoad that can be called again and again whenever this view needs to be
// refreshed
- (void)refreshView
{    
    self.viewsLabel.text = [NSString stringWithFormat:@"%u views", [self.scene.numberOfViews unsignedIntValue]];
    self.likesLabel.text = [NSString stringWithFormat:@"%u likes", [self.scene.numberOfLikes unsignedIntValue]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
    
    self.timeLabel.text = [dateFormat stringFromDate:self.scene.dateCreated];
    
    [self toggleSceneLikeButtonLabel];
    [self toggleSceneFollowButtonLabel];
    
    if (self.scene.previousScene == nil)
        [self refreshStoryView];
    else
        [self refreshSceneView];
    
    if ([self.userManagementModule isUserSignedIntoApp]) {
        // User signed in
        self.actionView.hidden = NO;
    } else {
        // User not signed in
        self.actionView.hidden = YES;
    }
}

- (void)viewDidUnload
{
    [self setLocationLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self setContentView:nil];
    [self setInfoView:nil];
    [self setUserManagementModule:nil];
    [self setActionView:nil];
    [self setImageView:nil];
    [self setSceneTextView:nil];
    [self setStoryTitleLabel:nil];
    [self setViewsLabel:nil];
    [self setLikesLabel:nil];
    [self setTimeLabel:nil];
    [self setLikeButton:nil];
    [self setFollowButton:nil];
    [self setShareButton:nil];
    [self setContributorsButton:nil];
    self.locationManager.delegate = nil;
    [self setLocationManager:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark target actions for read scene buttons
- (IBAction)storyContributors
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] 
                                                              initWithSearchBarAndNavigationControllerForInvitationType:INVITED_CONTRIBUTORS_STRING 
                                                              delegate:self 
                                                              selectedContacts:self.scene.story.invitedToContribute];
    
    [self.navigationController pushViewController:invitedTableViewController animated:YES];
}

- (IBAction)listStories:(id)sender 
{
    [self.delegate doneWithReadSceneViewController:self];
}

- (IBAction)addScene:(UIBarButtonItem *)sender 
{
    ModifySceneViewController *addSceneViewController = [[ModifySceneViewController alloc] init];
    addSceneViewController.editMode = add;
    addSceneViewController.scene = self.scene;
    addSceneViewController.delegate = self;
    [addSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [addSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:addSceneViewController animated:YES completion:nil];
}
- (IBAction)editScene:(UIBarButtonItem *)sender 
{
    ModifySceneViewController *editSceneViewController = [[ModifySceneViewController alloc] init];
    editSceneViewController.editMode = edit;
    editSceneViewController.scene = self.scene;
    editSceneViewController.delegate = self;
    [editSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [editSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:editSceneViewController animated:YES completion:nil];
}

- (IBAction)toggleSceneTextDisplay:(UIBarButtonItem *)sender 
{
    self.sceneTextView.hidden = self.sceneTextView.hidden ? NO : YES;
    self.storyTitleLabel.hidden = self.storyTitleLabel.hidden ? NO : YES;
}

- (void)toggleSceneLikeButtonLabel
{
    if (self.scene.liked)
        [self.likeButton setTitle:@"Liked" forState:UIControlStateNormal];
    else {
        [self.likeButton setTitle:@"Like" forState:UIControlStateNormal];
    }
    self.likesLabel.text = [NSString stringWithFormat:@"%u likes", [self.scene.numberOfLikes unsignedIntValue]];
}

- (void)toggleSceneFollowButtonLabel
{
    if (self.scene.favourite)
        [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
    else {
        [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
    }
}

- (IBAction)like:(UIButton *)sender 
{
    NSLog(@"Liked!");
    if (self.scene.previousScene == nil) {
        [Story toggleLikedStory:self.scene.story];
        [TestFlight passCheckpoint:@"Like story"];
    }
    [Scene toggleLikedScene:self.scene];
    [self toggleSceneLikeButtonLabel];
    [TestFlight passCheckpoint:@"Like scene"];
}

- (IBAction)follow:(UIButton *)sender
{
    NSLog(@"Following!");
    if (self.scene.previousScene == nil) {
        [Story toggleFavouritedStory:self.scene.story];
        [TestFlight passCheckpoint:@"Follow story"];
    }
    [Scene toggleFavouritedScene:self.scene];
    [self toggleSceneFollowButtonLabel];
    
    [TestFlight passCheckpoint:@"Follow scene"];
}

- (IBAction)share:(id)sender 
{    
    if (!self.scene.story.initialized) {
        NSLog(@"%s Can't share yet as story with title %@ is not initialized", __PRETTY_FUNCTION__, self.scene.story.title);
        return;
    }
    
    if (![[BanyanAPIEngine sharedEngine] isReachable]) {
        NSLog(@"%s Can't connect to internet", __PRETTY_FUNCTION__);
        [ParseAPIEngine showNetworkUnavailableAlert];
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:self.scene.story.storyId forKey:@"object_id"];
    MKNetworkOperation *op = [[BanyanAPIEngine sharedEngine] operationWithPath:BANYAN_API_GET_OBJECT_LINK_URL()
                                                                        params:params
                                                                   httpMethod:@"GET" 
                                                                          ssl:NO];
    
    [op 
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         PF_Facebook *pfFacebook = [PFFacebookUtils facebook];
         
         NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        @"Banyan", @"name",
                                        @"Story shared", @"caption",
                                        [response objectForKey:@"link"], @"link",
                                        nil];
         
         if (UIImagePNGRepresentation(self.imageView.image) != NULL)
             [params setObject:self.imageView.image forKey:@"picture"];
         
         if (![self.scene.story.title isEqualToString:@""])
             [params setObject:self.scene.story.title forKey:@"description"];
         else
             [params setObject:@"Untitled Story" forKey:@"description"];
         
         
         [pfFacebook dialog:@"feed" 
                  andParams:params 
                andDelegate:self.userManagementModule];
         
         [TestFlight passCheckpoint:@"Story shared"];

     }
     onError:BANYAN_ERROR_BLOCK()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}

- (IBAction)tap:(UITapGestureRecognizer *)sender 
{
    [self.delegate setReadSceneControllerEditMode:(![self.delegate readSceneControllerEditMode])];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    self.storyTitleLabel.alpha = [self.delegate readSceneControllerEditMode] ? 0 : 1;
    self.infoView.alpha = [self.delegate readSceneControllerEditMode] ? 1 : 0;
    self.actionView.alpha = [self.delegate readSceneControllerEditMode] ? 1 : 0;
    [UIView commitAnimations];
    
    [[UIApplication sharedApplication] setStatusBarHidden:![self.delegate readSceneControllerEditMode] 
                                            withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:![self.delegate readSceneControllerEditMode] animated:YES];
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark ModifySceneViewControllerDelegate
- (void) modifySceneViewController:(ModifySceneViewController *)controller
             didFinishEditingScene:(Scene *)scene
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:![self.delegate readSceneControllerEditMode] 
                                                withAnimation:UIStatusBarAnimationNone];
        [self.navigationController setNavigationBarHidden:![self.delegate readSceneControllerEditMode] animated:NO];

    }];
    NSLog(@"ReadSceneViewController_Editing scene");
}

- (void) modifySceneViewController:(ModifySceneViewController *)controller
              didFinishAddingScene:(Scene *)scene
{
    NSLog(@"ReadSceneViewController_Adding scene");
    [self.delegate readSceneViewControllerAddedNewScene:self];    
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

- (void) modifySceneViewController:(ModifySceneViewController *)controller
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
    if ([invitingType isEqualToString:INVITED_CONTRIBUTORS_STRING])
    {
        self.scene.story.invitedToContribute = contactsList;
    }
    else if ([invitingType isEqualToString:INVITED_VIEWERS_STRING]) 
    {
        self.scene.story.invitedToView = contactsList;
    }
    [Story editStory:self.scene.story];
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
