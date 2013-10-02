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
#import "Piece+Delete.h"
#import "ModifyStoryViewController.h"

@interface StoryReaderController ()
@property (strong, nonatomic) Piece *currentPiece;

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *settingsButton;
@property (strong, nonatomic) UIBarButtonItem *titleLabel;

@end

@implementation StoryReaderController
@synthesize pageViewController = _pageViewController;
@synthesize story = _story;
@synthesize currentPiece = _currentPiece;
@synthesize toolbar = _toolbar;
@synthesize cancelButton = _cancelButton;
@synthesize settingsButton = _settingsButton;
@synthesize titleLabel = _titleLabel;

- (void)setCurrentPiece:(Piece *)currentPiece
{
    _currentPiece = currentPiece;
    currentPiece.story.currentPieceNum = currentPiece.pieceNumber;
}

- (id)init
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

- (id)initWithPiece:(Piece *)piece
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.currentPiece = piece;
    }
    return self;
}

#define BUTTON_SPACING 5.0f

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.story.title;
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsButton"] style:UIBarButtonItemStyleDone target:self action:@selector(settingsPopup:)];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    titleButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:15];
    titleButton.titleLabel.minimumScaleFactor = 0.7;
    [titleButton setTitleColor:BANYAN_BLACK_COLOR forState:UIControlStateNormal];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleButton setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.5] forState:UIControlStateNormal];
    [titleButton setTitle:self.title forState:UIControlStateNormal];
    if (self.story.canContribute) {
        titleButton.showsTouchWhenHighlighted = YES;
        [titleButton addTarget:self action:@selector(editStoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        titleButton.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.title
                                                                                attributes:@{NSUnderlineStyleAttributeName: @1}];;
    }
    
    [self.navigationItem setTitleView:titleButton];
    [self performSelector:@selector(hideNavigationBar:) withObject:nil afterDelay:1];
    
    [Story viewedStory:self.story];
    
    UIPageViewControllerTransitionStyle pageTurnAnimation = UIPageViewControllerTransitionStylePageCurl;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:BNUserDefaultsUserPageTurnAnimation])
        pageTurnAnimation = UIPageViewControllerTransitionStyleScroll;
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:pageTurnAnimation
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
    self.pageViewController.delegate = self;
    
    NSArray *viewControllers = [NSArray arrayWithObject:[self viewControllerWithPiece:self.currentPiece]];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    self.pageViewController.dataSource = self;

    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    self.pageViewController.view.frame = self.view.bounds;
    [self.pageViewController didMoveToParentViewController:self];
    
    UISwipeGestureRecognizer* swipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showNavigationBar:)];
    swipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    
//    [self.pageViewController.gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer *gR, NSUInteger idx, BOOL *stop){
//        gR.delegate = self;
//        [gR requireGestureRecognizerToFail:swipeDownGestureRecognizer]; // So that a swipe down does not cause page turn
//    }];

    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    [self.view addGestureRecognizer:swipeDownGestureRecognizer];
    
    [TestFlight passCheckpoint:@"Story started to be read"];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.pageViewController = nil;
    self.currentPiece = nil;
    self.toolbar = nil;
    self.cancelButton = nil;
    self.settingsButton = nil;
    self.titleLabel = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark
# pragma mark target actions

- (IBAction)hideNavigationBar:(id)sender
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (IBAction)showNavigationBar:(id)sender
{
    if (!self.navigationController.navigationBarHidden)
        return;
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self performSelector:@selector(hideNavigationBar:) withObject:sender afterDelay:2];
}

- (void)settingsPopup:(id)sender
{
    UIActionSheet *actionSheet = nil;
    if (self.story.canContribute && [BanyanAppDelegate loggedIn]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Add a piece", @"Edit piece", @"Delete piece", @"Share via Facebook", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Share via Facebook", nil];
    }

    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

- (void)editStoryButtonPressed:(id)sender
{
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    ModifyStoryViewController *newStoryViewController = [[ModifyStoryViewController alloc] initWithStory:self.story];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newStoryViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void) deletePiece:(Piece *)piece
{
    NSUInteger curPieceNum = self.currentPiece.pieceNumber;
    NSNumber *turnToPage = nil;
    if (curPieceNum != [self.story.pieces count]) {
        turnToPage = [NSNumber numberWithUnsignedInteger:curPieceNum];
    } else { // This was the last piece
        turnToPage = [NSNumber numberWithUnsignedInteger:curPieceNum-1];
    }
    [Piece deletePiece:self.currentPiece];
    
    if (!self.story.pieces.count) {
        [self prepareToGoToStoryList];
    } else {
        [self readPieceViewControllerFlipToPiece:turnToPage];
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
        // delete story
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Add a piece"]) {
        Piece *piece = [Piece newPieceDraftForStory:self.story];
        ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:piece];
        addPieceViewController.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
        [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Edit piece"]) {
        ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:self.currentPiece];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
        //    addSceneViewController.delegate = self;
        [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete piece"]) {
        // Do this after a delay so that the action sheet can be dismissed
        [self performSelector:@selector(deletePiece:) withObject:self.currentPiece afterDelay:0.5];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share via Facebook"]) {
        // Share
        [self.currentPiece shareOnFacebook];
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
    // Dismiss the read scenes page view controller
    [self dismissReadView];
}

# pragma mark - UIPageViewControllerDataSource
// View controller to display after the current view controller has been turned ahead
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
       viewControllerAfterViewController:(UIViewController *)viewController
{
    
    NSUInteger pieceNum = [self pieceNumberForViewController:(ReadPieceViewController *)viewController];
    
    if (pieceNum >= self.story.length) {
        // Go to next story or go to Story List
        [self dismissReadView];
        return nil;
    }
    else {
        pieceNum++;
        ReadPieceViewController *nextVC = [self viewControllerAtPieceNumber:pieceNum];
        return nextVC;
    }
}

// View controller to display after the current view controller has been turned back
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger pieceNum = [self pieceNumberForViewController:(ReadPieceViewController *)viewController];
    
    if (pieceNum <= 1) {
        // Go to story list
        [self dismissReadView];
        return nil;
    }
    else {
        pieceNum--;
        ReadPieceViewController *previousVC = [self viewControllerAtPieceNumber:pieceNum];
        return previousVC;
    }
}

- (NSUInteger)pieceNumberForViewController:(ReadPieceViewController *)viewController
{
    Piece *piece = viewController.piece;
    return piece.pieceNumber;
}

- (ReadPieceViewController *)viewControllerAtPieceNumber:(NSUInteger)pieceNum
{
    if ([self.story.pieces count] >= pieceNum)
    {
        Piece *piece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:pieceNum]];
        if (!piece)
            return nil;
        return [self viewControllerWithPiece:piece];
    }
    else {
        return nil;
    }
}

- (ReadPieceViewController *)viewControllerWithPiece:(Piece *)piece
{
    if (!piece)
        return nil;
    
    ReadPieceViewController *readPieceViewController = [[ReadPieceViewController alloc] initWithPiece:piece];
    readPieceViewController.delegate = self;
    
    return readPieceViewController;
}

#pragma mark ModifyPieceViewControllerDelegate
- (void)modifyPieceViewController:(ModifyPieceViewController *)controller didFinishAddingPiece:(Piece *)piece
{
    [self readPieceViewControllerFlipToPiece:[NSNumber numberWithInt:piece.pieceNumber]];
}

#pragma mark ReadPieceViewControllerDelegate
- (BOOL)readPieceViewControllerFlipToPiece:(NSNumber *)pieceNumber
{
    NSUInteger oldPieceNum = self.currentPiece.pieceNumber;
    NSUInteger newPieceNum = [pieceNumber unsignedIntegerValue];
    UIPageViewControllerNavigationDirection direction;
    if (oldPieceNum < newPieceNum)
        direction = UIPageViewControllerNavigationDirectionForward;
    else if (oldPieceNum > newPieceNum)
        direction = UIPageViewControllerNavigationDirectionReverse;
    else
        return true; // Same piece as now, so not turning
    
    Piece *piece = [self.story.pieces objectAtIndex:newPieceNum-1];
    UIViewController *viewController = [self viewControllerWithPiece:piece];
    if (viewController) {
        // Get the previous piece
        NSArray *vc = [NSArray arrayWithObject:viewController];
        [self.pageViewController setViewControllers:vc direction:direction animated:YES completion:nil];
        return true;
    }
    return false;
}

- (void) dismissReadView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIControl class]]
        || [touch.view isKindOfClass:[UIButton class]]
        || [touch.view isKindOfClass:[UIBarButtonItem class]]
        || [touch.view isKindOfClass:[UIToolbar class]]) {
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
