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
#import "Piece+Create.h"

@interface StoryReaderController ()
@property (strong, nonatomic) Piece *currentPiece;
@end

@implementation StoryReaderController
@synthesize pageViewController = _pageViewController;
@synthesize story = _story;
@synthesize delegate = _delegate;
@synthesize currentPiece;

// First page of the view controller
- (UIViewController *)startStoryTelling
{
    ReadPieceViewController *startVC = [self viewControllerAtIndex:0];
    currentPiece = startVC.piece;
    return startVC;
}

- (void)viewWillAppear:(BOOL)animated
{    
    [super viewWillAppear:animated];
}

- (void) userLoginStatusChanged
{
    [self.story resetPermission];
}

-(BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.story.title;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(settingsPopup:)];
    
    [Story viewedStory:self.story];
    
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
        
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogInNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged) 
                                                 name:BNUserLogOutNotification
                                               object:nil];
    
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Story with id %@ started to be read", self.story.bnObjectId]];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.pageViewController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//- (void)drawRect:(CGRect)rect {
//    
//    UIImage *myImage = [UIImage imageNamed:@"pumpkin.jpg"];
//    
//    CGRect imageRect = CGRectMake(10, 10, 300, 400);
//    
//    [myImage drawInRect:imageRect];    
//}

# pragma mark
# pragma mark target actions
- (void)settingsPopup:(UIBarButtonItem *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Add a piece", @"Edit piece", @"Share via Facebook", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

// Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // DO NOTHING ON CANCEL
    }
    else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // delete story
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Add a piece"]) {
        Piece *piece = [Piece newPieceDraftForStory:self.story];
        ModifyPieceViewController *addSceneViewController = [[ModifyPieceViewController alloc] initWithPiece:piece];
        //    addSceneViewController.delegate = self;
        [addSceneViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:addSceneViewController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Edit piece"]) {
        ModifyPieceViewController *addSceneViewController = [[ModifyPieceViewController alloc] initWithPiece:currentPiece];
        //    addSceneViewController.delegate = self;
        [addSceneViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:addSceneViewController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share via Facebook"]) {
        // Share
    }
    else {
        NSLog(@"StoryReaderController_actionSheetclickedButtonAtIndex %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
    }
}

# pragma mark - HUD when transitioning back
- (void)prepareToGoToStoryList
{
    self.view.gestureRecognizers = nil;
    [self performSelector:@selector(hideHUDAndDone) withObject:self afterDelay:HUD_STAY_DELAY];
}

- (void)hideHUDAndDone
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self doneWithReadPieceViewController:nil];
}

# pragma mark - UIPageViewControllerDataSource
// View controller to display after the current view controller has been turned ahead
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
       viewControllerAfterViewController:(UIViewController *)viewController
{
    
    NSUInteger index = [self indexOfViewController:(ReadPieceViewController *)viewController];
    index++;
    
    if (index >= [self.story.length unsignedIntegerValue]  || index == NSNotFound) {
        NSLog(@"End of story reached for story %@", self.story.title);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"End of story";
        hud.detailsLabelText = self.story.title;
        [self prepareToGoToStoryList];
        currentPiece = nil;
        return nil;
    }
    else {
        ReadPieceViewController *nextVC = [self viewControllerAtIndex:index];
        currentPiece = nextVC.piece;
        return nextVC;
    }
}

// View controller to display after the current view controller has been turned back
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(ReadPieceViewController *)viewController];
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
        ReadPieceViewController *previousVC = [self viewControllerAtIndex:index];
        currentPiece = previousVC.piece;
        return previousVC;
    }
}

- (NSUInteger)indexOfViewController:(ReadPieceViewController *)viewController
{
    return [self.story.pieces indexOfObject:viewController.piece];
}

- (ReadPieceViewController *)viewControllerAtIndex:(NSUInteger)index
{
    ReadPieceViewController *readSceneViewController = [[ReadPieceViewController alloc] initWithPiece:[self.story.pieces objectAtIndex:index]];
    readSceneViewController.delegate = self;

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

- (ReadPieceViewController *)viewControllerForPieceNumberInStory:(NSUInteger)pieceNumber
{
    ReadPieceViewController *readSceneViewController = [[ReadPieceViewController alloc] initWithPiece:[self pieceAtPieceNumber:pieceNumber]];
    readSceneViewController.delegate = self;
    return readSceneViewController;
}

#pragma mark ReadPieceViewControllerDelegate
- (void)doneWithReadPieceViewController:(ReadPieceViewController *)readPieceViewController
{
    [self.delegate storyReaderContollerDone:self];
    // Dismiss the read scenes page view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)readPieceViewControllerAddedNewPiece:(ReadPieceViewController *)readPieceViewController
{
//    NSArray *vc = [NSArray arrayWithObject:[self pageViewController:self.pageViewController viewControllerAfterViewController:readSceneViewController]];
    NSArray *vc = [NSArray arrayWithObject:[self viewControllerForPieceNumberInStory:[self.story.length unsignedIntegerValue]]];
    [self.pageViewController setViewControllers:vc direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

- (void)readPieceViewControllerDeletedPiece:(ReadPieceViewController *)readPieceViewController
{
    NSUInteger deletedPieceNumber = [readPieceViewController.piece.pieceNumber unsignedIntegerValue];
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

- (void)readPieceViewControllerDeletedStory:(ReadPieceViewController *)readPieceViewController
{
    [self.delegate storyReaderContollerDone:self];
    // Dismiss the read scenes page view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
