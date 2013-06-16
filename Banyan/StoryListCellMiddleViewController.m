//
//  StoryListCellMiddleViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/21/13.
//
//

#import "StoryListCellMiddleViewController.h"
#import "StoryListCellReadSceneViewController.h"
#import "Story.h"
#import "SMPageControl.h"
#import "BanyanConnection.h"
#import "Piece.h"
#import "BanyanAppDelegate.h"

@interface StoryListCellMiddleViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *viewControllers;

@end

@implementation StoryListCellMiddleViewController

@synthesize story = _story;
@synthesize scrollView = _scrollView;
@synthesize pageControl = _pageControl;
@synthesize viewControllers = _viewControllers;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.viewControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentSize = CGSizeZero;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    self.pageControl.numberOfPages = 0;
    self.pageControl.currentPage = 0;
    self.pageControl.hidesForSinglePage = YES;
}

- (void)setStory:(Story *)story
{
    // When a piece is added, the story context changes and hence the StoryList FRC updates. This causes all
    // the cells to be reloaded and this function is called due to StoryListCell::setStory().
    // Therefore this function should do those things that does not unnecessarily update things everytime the
    // managed context is changed.
    
    // Don't do anything here if the story or number of pieces in the story hasn't changed.
    if (!story || ([_story isEqual:story] && [self.viewControllers count] == [story.pieces count])) {
        return;
    }
    
    _story = story;

    [self refreshView];
    self.pageControl.currentPage = story.currentPieceNum-1;
    self.pageControl.numberOfPages = [_story.length unsignedIntegerValue];

    if ([_story.length unsignedIntegerValue]) {        
        [self loadScrollViewWithPage:story.currentPieceNum-1];
        [self loadScrollViewWithPage:story.currentPieceNum];
    } else if ([BanyanAppDelegate loggedIn]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.y += 2.0f;
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"No pieces in the story.\nClick to add a piece!";
        label.font = [UIFont fontWithName:@"Roboto-Bold" size:20];
        label.textColor = BANYAN_GREEN_COLOR;
        label.numberOfLines = 2;
        label.backgroundColor = BANYAN_WHITE_COLOR;
        [self.scrollView addSubview:label];
    } else {
        CGRect frame = self.scrollView.bounds;
        frame.origin.y += 2.0f;
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"No pieces in the story yet.\nLog in to contribute.";
        label.font = [UIFont fontWithName:@"Roboto-Bold" size:20];
        label.textColor = BANYAN_GREEN_COLOR;
        label.numberOfLines = 2;
        label.backgroundColor = BANYAN_WHITE_COLOR;
        [self.scrollView addSubview:label];
    }
}

// rotation support for iOS 5.x and earlier, note for iOS 6.0 and later this will not be called
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    // return YES for supported orientations
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
#endif

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self refreshView];
    
    [self loadScrollViewWithPage:self.pageControl.currentPage - 1];
    [self loadScrollViewWithPage:self.pageControl.currentPage];
    [self loadScrollViewWithPage:self.pageControl.currentPage + 1];
    [self gotoPage:NO]; // remain at the same page (don't animate)
}

- (void) refreshView
{
    // remove all the subviews from our scrollview
    for (UIView *view in self.scrollView.subviews)
    {
        [view removeFromSuperview];
    }
    
    NSUInteger numPages = [self.story.length unsignedIntegerValue];
    
    // adjust the contentSize (larger or smaller) depending on the orientation
    self.scrollView.contentSize =
    CGSizeMake(CGRectGetWidth(self.scrollView.frame) * numPages, CGRectGetHeight(self.scrollView.frame));

    // clear out and reload our pages
    self.viewControllers = nil;
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < numPages; i++)
    {
		[controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
}

- (void)loadScrollViewWithPage:(NSUInteger)page
{
    NSUInteger pieceNum = page+1;
    
    if (!pieceNum || pieceNum > [self.story.length unsignedIntegerValue])
        return;
    
    // replace the placeholder if necessary
    StoryListCellReadSceneViewController *controller = [self.viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null])
    {
        controller = [[StoryListCellReadSceneViewController alloc] init];
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    if (controller.view.superview != nil)
        return;
    
    // add the controller's view to the scroll view
    CGRect frame = self.scrollView.frame;
    frame.origin.x = CGRectGetWidth(frame) * page;
    frame.origin.y = 0;
    controller.view.frame = frame;
    
    [self addChildViewController:controller];
    [self.scrollView addSubview:controller.view];
    [controller didMoveToParentViewController:self];
    
    Piece *piece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:pieceNum]];
    
    if (piece)
    {        
        [controller setPiece:piece];
        return;
    }

    [controller setStatus:@"Fetching this piece..."];

    [BanyanConnection loadPiecesForStory:self.story atPieceNumbers:@[[NSNumber numberWithUnsignedInteger:pieceNum]]
                         completionBlock:^{
                             Piece *updatedPiece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:pieceNum]];
                             if (updatedPiece) {
                                 [controller setPiece:updatedPiece];
                             }
                         }
                              errorBlock:^(NSError *error){
                                  NSLog(@"Error in StoryListCellMiddleViewController:loadScrollViewWithPage Could not load piece");
                                  [controller setStatus:[NSString stringWithFormat:@"Error: %@ in fetching this piece", error.localizedDescription]];

                              }];
}

// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = CGRectGetWidth(self.scrollView.frame);
    NSUInteger page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
    self.story.currentPieceNum = page + 1;

    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    
    // TODO a possible optimization would be to unload the views+controllers which are no longer visible
}

- (void)gotoPage:(BOOL)animated
{
    NSInteger page = self.pageControl.currentPage;
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    
	// update the scroll view to the appropriate page
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    [self.scrollView scrollRectToVisible:bounds animated:animated];
}

- (IBAction)changePage:(id)sender
{
    [self gotoPage:YES];    // YES = animate
}

#pragma mark instance methods
- (Piece *)currentlyVisiblePiece
{
    if (!self.story || ![self.story.pieces count])
        return nil;
    NSUInteger pieceNum = self.story.currentPieceNum;
    Piece *piece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:pieceNum]];
    return piece;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
