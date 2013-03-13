//
//  ScenesViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryReaderController.h"
#import "Story+Stats.h"
#import "Story+Permissions.h"
#import "MBProgressHUD.h"

@interface StoryReaderController ()

@property (strong, nonatomic) IBOutlet UIBarButtonItem *addSceneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editSceneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *hideTextButton;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *likeButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareButton;

@end

@implementation StoryReaderController
@synthesize pageViewController = _pageViewController;
@synthesize story = _story;
@synthesize delegate = _delegate;
@synthesize readSceneControllerEditMode = _readSceneControllerEditMode;
@synthesize addSceneButton = _addSceneButton;
@synthesize editSceneButton = _editSceneButton;
@synthesize hideTextButton = _hideTextButton;
@synthesize likeButton = _likeButton;
@synthesize shareButton = _shareButton;

// First page of the view controller
- (UIViewController *)startStoryTelling
{
    return [self viewControllerAtIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{    
    [super viewWillAppear:animated];
    [self setWantsFullScreenLayout:YES];
}

- (void) userLoginStatusChanged
{
    [self.story resetPermission];
    [self refreshView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Story viewedStory:self.story];
    
    // START: NAVIGATION BAR SETTINGS
    // Add Buttons to Navigation Bar
    // These should be added before doing startStoryTelling as the target-actions are set at the time of alloc-init of 
    // ReadSceneViewControllers
    // These are the buttons that provide different actions for read scene controllers
    // Create a "Hide Text" button
    self.hideTextButton = [[UIBarButtonItem alloc] initWithTitle:@"aA" style:UIBarButtonItemStyleBordered target:nil action:nil];
    // Create an 'Edit Scene' button
    self.editSceneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:nil action:nil];
    // Create an 'Add Scene' Button
    self.addSceneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[self.navigationController navigationBar] setTranslucent:YES];    
    // END: NAVIGATION BAR SETTINGS
    
    // START: TOOLBAR SETTINGS
    self.likeButton = [[UIBarButtonItem alloc] initWithTitle:@"Like" style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.likeButton.possibleTitles = [NSSet setWithObjects:@"Like", @"Unlike", nil];
    self.shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
    [self.navigationController setToolbarHidden:YES animated:YES];
    [[self.navigationController toolbar] setTranslucent:YES];
    
    // END: TOOLBAR SETTINGS
    
    self.readSceneControllerEditMode = NO;
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    
    NSArray *viewControllers = [NSArray arrayWithObject:[self startStoryTelling]];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    self.pageViewController.dataSource = self;
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    
    // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
    CGRect pageViewRect = self.view.bounds;
    self.pageViewController.view.frame = pageViewRect;
    
    [self.pageViewController didMoveToParentViewController:self];
    
    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
//    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    
    [self refreshView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogInNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogOutNotification
                                               object:nil];
    
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Story with id %@ started to be read", self.story.storyId]];
}

- (void) refreshView
{
    UserManagementModule *userManagementModule = [(BanyanAppDelegate *)[[UIApplication sharedApplication] delegate] userManagementModule];
    if ([userManagementModule isUserSignedIntoApp] && self.story.canContribute) {
        // User signed in AND User can Contribute
        
        NSMutableArray *rightSideButtons = [[NSMutableArray alloc] initWithCapacity:5];
        // "Hide Text" button
        [rightSideButtons addObject:self.hideTextButton];
        // Add a Spacer
        [rightSideButtons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil]];
        // 'Edit Scene' button
        [rightSideButtons addObject:self.editSceneButton];
        // Add a Spacer
        [rightSideButtons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil]];
        // "Add Scene' Button
        [rightSideButtons addObject:self.addSceneButton];
        self.navigationItem.rightBarButtonItems = rightSideButtons;
        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        NSArray *toolbarButtons = [NSArray arrayWithObjects:self.likeButton, flexibleSpace, self.shareButton, nil];
        self.toolbarItems = toolbarButtons;
    } else {
        // User not signed in OR User can not contribute

        NSMutableArray *rightSideButtons = [[NSMutableArray alloc] initWithCapacity:1];
        // "Hide Text" button
        [rightSideButtons addObject:self.hideTextButton];
        self.navigationItem.rightBarButtonItems = rightSideButtons;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.addSceneButton = nil;
    self.editSceneButton = nil;
    self.hideTextButton = nil;
    self.pageViewController = nil;
    [self setLikeButton:nil];
    [self setShareButton:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:![self readSceneControllerEditMode]
                                            withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:![self readSceneControllerEditMode] animated:YES];
    [self.navigationController setToolbarHidden:![self readSceneControllerEditMode] animated:YES];
    
    [super viewWillDisappear:animated];
}

# pragma mark - HUD when transitioning back
- (void)prepareToGoToStoryList
{
    self.view.gestureRecognizers = nil;
    self.readSceneControllerEditMode = YES; // So that ViewWillDisapper transitions properly
    [self performSelector:@selector(hideHUDAndDone) withObject:self afterDelay:HUD_STAY_DELAY];
}

- (void)hideHUDAndDone
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self doneWithReadSceneViewController:nil];
}

# pragma mark - UIPageViewControllerDataSource
// View controller to display after the current view controller has been turned ahead
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
       viewControllerAfterViewController:(UIViewController *)viewController
{
    
    NSUInteger index = [self indexOfViewController:(ReadSceneViewController *)viewController];
    index++;
    
    if (index >= [self.story.length unsignedIntegerValue]  || index == NSNotFound) {
        NSLog(@"End of story reached for story %@", self.story.title);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"End of story";
        hud.detailsLabelText = self.story.title;
        [self prepareToGoToStoryList];
        return nil;
    }
    else
        return [self viewControllerAtIndex:index];
}

// View controller to display after the current view controller has been turned back
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(ReadSceneViewController *)viewController];
    NSLog(@"index: %d notfound: %d", index, NSNotFound);
    
    if (index == 0 || index == NSNotFound) {
        NSLog(@"Beginning of story reached for story %@", self.story.title);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"Beginning of story";
        hud.detailsLabelText = @"Going back to story list";
        [self prepareToGoToStoryList];
        return nil;
    }
    else {
        index--;
        return [self viewControllerAtIndex:index];
    }
}

- (NSUInteger)indexOfViewController:(ReadSceneViewController *)viewController
{
    return [self.story.pieces indexOfObject:viewController.piece];
}

- (ReadSceneViewController *)viewControllerAtIndex:(NSUInteger)index
{
    ReadSceneViewController *readSceneViewController = [[ReadSceneViewController alloc] init];
    readSceneViewController.piece = [self.story.pieces objectAtIndex:index];
    readSceneViewController.delegate = self;
    [self setNavBarButtonsWithTargetActionsFromReadSceneViewController:readSceneViewController];

//    // Prevent the buttons in the readSceneViewController to trigger page changes
//    for (UIGestureRecognizer *gesture in self.pageViewController.gestureRecognizers)
//        gesture.delegate = self;
    
    return readSceneViewController;
}

- (Piece *)pieceAtPieceNumber:(NSUInteger)pieceNumber
{
    // Pieces are already sorted on pieceNumber    
    return [self.story.pieces objectAtIndex:pieceNumber-1];
}

- (ReadSceneViewController *)viewControllerForPieceNumberInStory:(NSUInteger)pieceNumber
{
    ReadSceneViewController *readSceneViewController = [[ReadSceneViewController alloc] init];
    readSceneViewController.piece = [self pieceAtPieceNumber:pieceNumber];
    readSceneViewController.delegate = self;
    [self setNavBarButtonsWithTargetActionsFromReadSceneViewController:readSceneViewController];
    return readSceneViewController;
}

-(void) setNavBarButtonsWithTargetActionsFromReadSceneViewController:(ReadSceneViewController *)readSceneViewController
{
    self.addSceneButton.target = self.editSceneButton.target = self.hideTextButton.target = readSceneViewController;
    self.likeButton.target = self.shareButton.target = readSceneViewController;
    
    self.addSceneButton.action = @selector(addPiece:);
    self.editSceneButton.action = @selector(editPiece:);
    self.hideTextButton.action = @selector(togglePieceTextDisplay:);
    
    self.likeButton.action = @selector(like:);
    self.shareButton.action = @selector(share:);
}
#pragma mark ReadSceneViewControllerDelegate
- (void)doneWithReadSceneViewController:(ReadSceneViewController *)readSceneViewController
{
    [self.delegate storyReaderContollerDone:self];
    // Dismiss the read scenes page view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)readSceneViewControllerAddedNewScene:(ReadSceneViewController *)readSceneViewController
{
//    NSArray *vc = [NSArray arrayWithObject:[self pageViewController:self.pageViewController viewControllerAfterViewController:readSceneViewController]];
    NSArray *vc = [NSArray arrayWithObject:[self viewControllerForPieceNumberInStory:[self.story.length unsignedIntegerValue]]];
    [self.pageViewController setViewControllers:vc direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

- (void)readSceneViewControllerDeletedScene:(ReadSceneViewController *)readSceneViewController
{
    NSUInteger deletedPieceNumber = [readSceneViewController.piece.pieceNumber unsignedIntegerValue];
    deletedPieceNumber = MAX(deletedPieceNumber, [self.story.length unsignedIntegerValue]);
    
    // Change this to come to the scene before or after the deleted scene
    UIViewController *viewController = [self viewControllerForPieceNumberInStory:deletedPieceNumber];
    if (viewController) {
        // Get the previous piece
        NSArray *vc = [NSArray arrayWithObject:viewController];
        [self.pageViewController setViewControllers:vc direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    } else {
        // No more pieces left
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"No more pieces left";
        hud.detailsLabelText = @"Going back to story list";
        [self prepareToGoToStoryList];
    }
}

- (void)readSceneViewControllerDeletedStory:(ReadSceneViewController *)readSceneViewController
{
    [self.delegate storyReaderContollerDone:self];
    // Dismiss the read scenes page view controller
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
