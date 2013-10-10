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

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *settingsButton;
@property (strong, nonatomic) UIBarButtonItem *titleLabel;
@property (nonatomic) BOOL transitionStyleScroll;
@property (strong, nonatomic) UIPanGestureRecognizer *dismissPanGestureRecognizer;

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
@synthesize dismissPanGestureRecognizer = _dismissPanGestureRecognizer;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.story.title;
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    [Story viewedStory:self.story];
    
    UIPageViewControllerTransitionStyle pageTurnAnimation = UIPageViewControllerTransitionStylePageCurl;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:BNUserDefaultsUserPageTurnAnimation]) {
        pageTurnAnimation = UIPageViewControllerTransitionStyleScroll;
        self.transitionStyleScroll = YES;
    } else {
        self.transitionStyleScroll = NO;
    }
    
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
    
//    [self.pageViewController.gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer *gR, NSUInteger idx, BOOL *stop){
//        gR.delegate = self;
//    }];

    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    
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


# pragma mark - UIPageViewControllerDataSource
// View controller to display after the current view controller has been turned ahead
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController 
       viewControllerAfterViewController:(UIViewController *)viewController
{
    
    NSUInteger pieceNum = [self pieceNumberForViewController:(ReadPieceViewController *)viewController];
    
    if (pieceNum >= self.story.length) {
        // Go to next story or go to Story List
        // Interaction gesture recognizer will take care of it
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
        // Interaction gesture recognizer will take care of it
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

- (void) readPieceViewControllerDoneReading
{
    [self dismissReadView];
}

- (void) interactionControllerDidWireToViewWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    gestureRecognizer.delegate = self;
    if (self.transitionStyleScroll) {
        // No interactive dismissal for Scroll type transition
        [self.view removeGestureRecognizer:gestureRecognizer];
        self.dismissPanGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        for (ReadPieceViewController *viewController in [self.pageViewController viewControllers]) {
            [viewController addGestureRecognizerToContentView:gestureRecognizer];
        }
    }
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    NSUInteger currentPieceNum = self.currentPiece.pieceNumber;
    
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if ([(UIPanGestureRecognizer*)gestureRecognizer velocityInView:gestureRecognizer.view].x > 0.0f) {
            // Going left
            Piece *piece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:currentPieceNum-1]];
            if (!piece)
                return YES;
        } else {
            // Going right
            Piece *piece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:currentPieceNum+1]];
            if (!piece)
                return NO; // For now
        }
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
