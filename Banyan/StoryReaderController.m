//
//  ScenesViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/14/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "StoryReaderController.h"
#import "Story+Stats.h"
#import "Story+Permissions.h"
#import "MBProgressHUD.h"
#import "Piece+Create.h"
#import "CEFlipAnimationController.h"
#import "BNHorizontalSwipeInteractionController.h"
#import "NextStoryViewController.h"
#import "ModifyPieceViewController.h"

@interface StoryReaderController (ModifyPieceViewControllerDelegate) <ModifyPieceViewControllerDelegate>

@end
@interface StoryReaderController (NextStoryViewControllerDelegate) <NextStoryViewControllerDelegate>
@end
@interface StoryReaderController (UIViewControllerTransitioningDelegate)<UIViewControllerTransitioningDelegate>
@end

@interface StoryReaderController () <ReadPieceViewControllerDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) Piece *currentPiece;

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *settingsButton;
@property (strong, nonatomic) UIBarButtonItem *titleLabel;
@property (nonatomic) BOOL transitionStyleScroll;
@property (strong, nonatomic) UIPanGestureRecognizer *dismissBackPanGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *dismissAheadPanGestureRecognizer;

@property (strong, nonatomic) CEFlipAnimationController *animationController;
@property (strong, nonatomic) BNHorizontalSwipeInteractionController *interactionController;

@end

@implementation StoryReaderController
@synthesize pageViewController = _pageViewController;
@synthesize story = _story;
@synthesize currentPiece = _currentPiece;
@synthesize toolbar = _toolbar;
@synthesize cancelButton = _cancelButton;
@synthesize settingsButton = _settingsButton;
@synthesize titleLabel = _titleLabel;
@synthesize transitionStyleScroll = _transitionStyleScroll;
@synthesize dismissBackPanGestureRecognizer = _dismissPanGestureRecognizer;
@synthesize dismissAheadPanGestureRecognizer = _dismissAheadPanGestureRecognizer;
@synthesize animationController = _animationController;
@synthesize interactionController = _interactionController;
@synthesize delegate = _delegate;

- (void)setCurrentPiece:(Piece *)currentPiece
{
    _currentPiece = currentPiece;
    currentPiece.story.currentPieceIndexNum = [currentPiece.story.pieces indexOfObject:currentPiece];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        // this should never be called directly.
        // initWithPiece should be called
        NSAssert(false, @"Use initWithPiece: to intialize this view controller");
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.story.title;
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    // Animation between view controllers
    self.animationController = [[CEFlipAnimationController alloc] init];
    self.interactionController = [[BNHorizontalSwipeInteractionController alloc] init];
    
    self.dismissAheadPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(showOptionsForNextStory:)];
    self.dismissAheadPanGestureRecognizer.delegate = self;
    
    [self.story setViewedWithCompletionBlock:nil];
    
//    UIPageViewControllerTransitionStyle pageTurnAnimation = UIPageViewControllerTransitionStylePageCurl;
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if (![defaults boolForKey:BNUserDefaultsUserPageTurnAnimation]) {
//        pageTurnAnimation = UIPageViewControllerTransitionStyleScroll;
//        self.transitionStyleScroll = YES;
//    } else {
//        self.transitionStyleScroll = NO;
//    }
    
    // No page turn curl animation. This is because there are two unsolved problems in this so far-
    // 1. App crashes when a piece is turned and the image of the previous piece is focussed
    // 2. Audio play button can not be clicked because the page turns on tap
    // Instead of devoting a lot of time on fixing it, removing this option for now.
    // Also removing it from the settings menu
    UIPageViewControllerTransitionStyle pageTurnAnimation = UIPageViewControllerTransitionStyleScroll;
    self.transitionStyleScroll = YES;

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

    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;

    BNLogInfo(@"Reading story with objectId %@ and title %@", REPLACE_NIL_WITH_EMPTY_STRING(self.story.bnObjectId), REPLACE_NIL_WITH_EMPTY_STRING(self.story.title));
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Story Reader"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark
# pragma mark target-actions
- (IBAction)showOptionsForNextStory:(UIGestureRecognizer *)gR
{    
    if (gR.state == UIGestureRecognizerStateBegan) {
        NextStoryViewController *nextStoryVc = [[NextStoryViewController alloc] init];
        nextStoryVc.delegate = self;
        nextStoryVc.nextStory = [self.delegate storyReaderControllerGetNextStory:self];
        nextStoryVc.currentStory = self.story;
        UINavigationController *nvVC = [[UINavigationController alloc] initWithRootViewController:nextStoryVc];
        nvVC.transitioningDelegate = self;
        [self presentViewController:nvVC animated:YES completion:nil];
    }
}

# pragma mark - UIPageViewControllerDataSource
// View controller to display after the current view controller has been turned ahead
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
       viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger pieceIndexNum = [self pieceIndexNumberForViewController:(ReadPieceViewController *)viewController];
    
    if (pieceIndexNum > self.story.length) {
        // Go to next story or go to Story List
        // Interaction gesture recognizer will take care of it
        return nil;
    }
    else {
        pieceIndexNum++;
        ReadPieceViewController *nextVC = [self viewControllerAtPieceIndexNumber:pieceIndexNum];
        return nextVC;
    }
}

// View controller to display after the current view controller has been turned back
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger pieceIndexNum = [self pieceIndexNumberForViewController:(ReadPieceViewController *)viewController];
    
    if (pieceIndexNum <= 0) {
        // Go to story list
        // Interaction gesture recognizer will take care of it
        return nil;
    }
    else {
        pieceIndexNum--;
        ReadPieceViewController *previousVC = [self viewControllerAtPieceIndexNumber:pieceIndexNum];
        return previousVC;
    }
}

- (NSUInteger)pieceIndexNumberForViewController:(ReadPieceViewController *)viewController
{
    Piece *piece = viewController.piece;
    return [piece.story.pieces indexOfObject:piece];
}

- (ReadPieceViewController *)viewControllerAtPieceIndexNumber:(NSUInteger)pieceIndexNum
{
    if (pieceIndexNum < [self.story.pieces count])
    {
        Piece *piece = [self.story.pieces objectAtIndex:pieceIndexNum];
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

#pragma mark ReadPieceViewControllerDelegate
-(BOOL)readPieceViewControllerFlipToPieceAtIndex:(NSUInteger)newPieceIndexNum
{
    NSUInteger oldPieceIndexNum = [self.currentPiece.story.pieces indexOfObject:self.currentPiece];
    UIPageViewControllerNavigationDirection direction;
    if (oldPieceIndexNum <= newPieceIndexNum)
        direction = UIPageViewControllerNavigationDirectionForward;
    else
        direction = UIPageViewControllerNavigationDirectionReverse;
    
    BOOL animation;
    if (self.transitionStyleScroll) {
        animation = NO;
    } else {
        animation = YES;
    }

    Piece *piece = nil;
    if (newPieceIndexNum < self.story.pieces.count) {
        piece = [self.story.pieces objectAtIndex:newPieceIndexNum];
    }
    UIViewController *viewController = [self viewControllerWithPiece:piece];
    if (viewController) {
        // Get the previous piece
        NSArray *vc = [NSArray arrayWithObject:viewController];
        [self.pageViewController setViewControllers:vc direction:direction animated:animation completion:nil];
        return true;
    }
    return false;
}

- (void) dismissReadViewAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    [self dismissViewControllerAnimated:animated completion:completion];
}

- (void) readPieceViewControllerDoneReading
{
    [self dismissReadViewAnimated:YES completion:nil];
}

# pragma mark
# pragma mark Interaction Controller methods
- (void) interactionControllerDidWireToViewWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    gestureRecognizer.delegate = self;
    if (self.transitionStyleScroll) {
        // No interactive dismissal for Scroll type transition
        [self.view removeGestureRecognizer:gestureRecognizer];
        self.dismissBackPanGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        for (ReadPieceViewController *viewController in [self.pageViewController viewControllers]) {
            [viewController addGestureRecognizerToContentView:gestureRecognizer];
        }
    }
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    NSUInteger currentPieceIndexNum = [self.currentPiece.story.pieces indexOfObject:self.currentPiece];

    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGr = (UIPanGestureRecognizer*)gestureRecognizer;
        if (   ([panGr velocityInView:gestureRecognizer.view].x > 0.0f)
            && (!self.transitionStyleScroll || (panGr == self.dismissBackPanGestureRecognizer))
            && (panGr != self.dismissAheadPanGestureRecognizer)) {
            // Going left
            if (currentPieceIndexNum < 1)
                return YES;
        } else if (([panGr velocityInView:gestureRecognizer.view].x < 0.0f) && panGr == self.dismissAheadPanGestureRecognizer) {
            // Going right
            if (currentPieceIndexNum >= self.currentPiece.story.pieces.count-1)
                return YES;
        } else
            ;
    }
    
    return NO;
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end

@implementation StoryReaderController (UIViewControllerTransitioningDelegate)

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    [self.interactionController wireToViewController:presented forOperation:CEInteractionOperationDismiss];
    
    self.animationController.reverse = YES;
    return self.animationController;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.animationController.reverse = NO;
    return self.animationController;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactionController.interactionInProgress ? self.interactionController : nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactionController.interactionInProgress ? self.interactionController : nil;
}

@end

@implementation StoryReaderController (NextStoryViewControllerDelegate)

- (void) nextStoryViewControllerGoToStoryList:(NextStoryViewController *)nextStoryViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) nextStoryViewControllerGoToStory:(Story *)nextStory
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate storyReaderControllerReadNextStory:nextStory];
    }];
}

- (void)nextStoryViewControllerAddPieceToStory:(NextStoryViewController *)nextStoryViewController
{
    Piece *piece = [Piece newPieceDraftForStory:self.story];
    ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:piece];
    addPieceViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentViewController:navController animated:YES completion:nil];
}

@end

@implementation StoryReaderController (ModifyPieceViewControllerDelegate)
- (void) modifyPieceViewController:(ModifyPieceViewController *)controller
              didFinishAddingPiece:(Piece *)piece
{
    [self readPieceViewControllerFlipToPieceAtIndex:[piece.story.pieces indexOfObject:piece]];
}

@end