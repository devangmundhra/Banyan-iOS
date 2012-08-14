//
//  ScenesViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ScenesViewController.h"
#import "ParseConnection.h"
#import "Story+Stats.h"
#import "StoryDocuments.h"
#import "MBProgressHUD.h"

@interface ScenesViewController ()

@property (strong, nonatomic) UIBarButtonItem *addSceneButton;
@property (strong, nonatomic) UIBarButtonItem *editSceneButton;
@property (strong, nonatomic) UIBarButtonItem *hideTextButton;

@property (weak, nonatomic) UserManagementModule *userManagementModule;

@end

@implementation ScenesViewController
@synthesize pageViewController = _pageViewController;
@synthesize story = _story;
@synthesize delegate = _delegate;
@synthesize readSceneControllerEditMode = _readSceneControllerEditMode;
@synthesize userManagementModule = _userManagementModule;
@synthesize addSceneButton = _addSceneButton;
@synthesize editSceneButton = _editSceneButton;
@synthesize hideTextButton = _hideTextButton;

- (UserManagementModule *)userManagementModule
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.userManagementModule.owningViewController = self;
    
    return delegate.userManagementModule;
}

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
    [ParseConnection resetPermissionsForStory:self.story];
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
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    
    [self refreshView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:USER_MANAGEMENT_MODULE_USER_LOGIN_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:USER_MANAGEMENT_MODULE_USER_LOGOUT_NOTIFICATION 
                                               object:nil];
    
    [TestFlight passCheckpoint:@"Story started to be read"];
}

- (void) refreshView
{    
    if ([self.userManagementModule isUserSignedIntoApp] && self.story.canContribute) {
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:![self readSceneControllerEditMode] animated:NO];
    [super viewWillDisappear:animated];
}

# pragma mark - UIPageViewControllerDataSource
// View controller to display after the current view controller has been turned ahead
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
       viewControllerAfterViewController:(UIViewController *)viewController
{
    
    NSUInteger index = [self indexOfViewController:(ReadSceneViewController *)viewController];
    index++;
    
    if (index >= [self.story.lengthOfStory unsignedIntegerValue]) {
        NSLog(@"End of story reached for story %@", self.story.title);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"End of story";
        hud.detailsLabelText = self.story.title;
        self.view.gestureRecognizers = nil;
        [self performSelector:@selector(hideHUDAndDone) withObject:self afterDelay:HUD_STAY_DELAY];   
        return nil;
    }
    else
        return [self viewControllerAtIndex:index];
}

- (void)hideHUDAndDone
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self doneWithReadSceneViewController:nil];  
}

// View controller to display after the current view controller has been turned back
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(ReadSceneViewController *)viewController];
    if (index <= 0) {
        NSLog(@"Beginning of story reached for story %@", self.story.title);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"Beginning of story";
        hud.detailsLabelText = @"Going back to story list";
        self.view.gestureRecognizers = nil;
        [self performSelector:@selector(hideHUDAndDone) withObject:self afterDelay:HUD_STAY_DELAY];
        return nil;
    }
    else {
        index--;
        return [self viewControllerAtIndex:index];
    }
}

- (NSUInteger)indexOfViewController:(ReadSceneViewController *)viewController
{
    return [self.story.scenes indexOfObject:viewController.scene];
}

- (ReadSceneViewController *)viewControllerAtIndex:(NSUInteger)index
{
    ReadSceneViewController *readSceneViewController = [[ReadSceneViewController alloc] init];
    readSceneViewController.scene = [self.story.scenes objectAtIndex:index];
    readSceneViewController.delegate = self;
    [self setNavBarButtonsWithTargetActionsFromReadSceneViewController:readSceneViewController];

    // Prevent the buttons in the readSceneViewController to trigger page changes
    for (UIGestureRecognizer *gesture in self.pageViewController.gestureRecognizers)
        gesture.delegate = self;
    
    return readSceneViewController;
}

- (Scene *)sceneAtSceneNumberInStory:(NSNumber *)sceneNumber
{
    // Assuming scenes is already sorted on sceneNumberInStory
    for (Scene *scene in self.story.scenes)
        if (scene.sceneNumberInStory == sceneNumber)
            return scene;
    
    return [self.story.scenes objectAtIndex:0];
}

- (ReadSceneViewController *)viewControllerForSceneNumberInStory:(NSNumber *)sceneNumber
{
    ReadSceneViewController *readSceneViewController = [[ReadSceneViewController alloc] init];
    readSceneViewController.scene = [self sceneAtSceneNumberInStory:sceneNumber];
    readSceneViewController.delegate = self;
    [self setNavBarButtonsWithTargetActionsFromReadSceneViewController:readSceneViewController];
    return readSceneViewController;
}

-(void) setNavBarButtonsWithTargetActionsFromReadSceneViewController:(ReadSceneViewController *)readSceneViewController
{
    self.addSceneButton.target = self.editSceneButton.target = self.hideTextButton.target = readSceneViewController;
    self.addSceneButton.action = @selector(addScene:);
    self.editSceneButton.action = @selector(editScene:);
    self.hideTextButton.action = @selector(toggleSceneTextDisplay:);
}
#pragma mark ReadSceneViewControllerDelegate
- (void)doneWithReadSceneViewController:(ReadSceneViewController *)readSceneViewController
{
    [StoryDocuments saveStoryToDisk:self.story];
    [self.delegate scenesViewContollerDone:self];
    // Dismiss the read scenes page view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)readSceneViewControllerAddedNewScene:(ReadSceneViewController *)readSceneViewController
{
    NSArray *vc = [NSArray arrayWithObject:[self pageViewController:self.pageViewController viewControllerAfterViewController:readSceneViewController]];
    [self.pageViewController setViewControllers:vc direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

- (void)readSceneViewControllerDeletedScene:(ReadSceneViewController *)readSceneViewController
{
    // Change this to come to the scene before or after the deleted scene
    NSArray *vc = [NSArray arrayWithObject:[self viewControllerForSceneNumberInStory:[NSNumber numberWithInt:0]]];
//    NSArray *vc = [NSArray arrayWithObject:[self pageViewController:self.pageViewController viewControllerBeforeViewController:readSceneViewController]];
    [self.pageViewController setViewControllers:vc direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
}

- (void)readSceneViewControllerDeletedStory:(ReadSceneViewController *)readSceneViewController
{
    [self.delegate scenesViewContollerDone:self];
    // Dismiss the read scenes page view controller
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
