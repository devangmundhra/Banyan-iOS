//
//  StoryListTableViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryListTableViewController.h"
#import "BanyanAppDelegate.h"
#import "Story+Delete.h"
#import "Piece+Create.h"
#import "StoryReaderController.h"
#import "MBProgressHUD.h"
#import "BanyanConnection.h"
#import "AFBanyanAPIClient.h"
#import "MasterTabBarController.h"

typedef enum {
    FilterStoriesSegmentIndexFollowing = 0,
    FilterStoriesSegmentIndexPopular
} FilterStoriesSegmentIndex;

@interface StoryListTableViewController ()
@property (strong, nonatomic) IBOutlet UISegmentedControl *filterStoriesSegmentedControl;
@property (strong, nonatomic) NSIndexPath *indexOfVisibleBackView;

@end

@implementation StoryListTableViewController
@synthesize filterStoriesSegmentedControl = _filterStoriesSegmentedControl;
@synthesize indexOfVisibleBackView = _indexOfVisibleBackView;

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleBlackTranslucent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];

    self.title = @"Stories";
    
    [self.tableView registerClass:[SingleStoryCell class] forCellReuseIdentifier:@"SingleStoryCell"];
    [self.view setBackgroundColor:BANYAN_LIGHTGRAY_COLOR];
    [self.tableView setSeparatorColor:BANYAN_LIGHTGRAY_COLOR];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.tableView setShowsHorizontalScrollIndicator:NO];
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    // Fetched results controller
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kBNStoryClassKey];
    NSSortDescriptor *uploadStatusSD = [NSSortDescriptor sortDescriptorWithKey:@"uploadStatusNumber" ascending:YES];
    NSSortDescriptor *newPiecesSD = [NSSortDescriptor sortDescriptorWithKey:@"newPiecesToView" ascending:YES];
    NSSortDescriptor *dateSD = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt"
                                                             ascending:NO
                                                              selector:@selector(compare:)];
    request.sortDescriptors = [NSArray arrayWithObjects:uploadStatusSD, newPiecesSD, dateSD, nil];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil]; // Adding cache causes issues in filtering after changing predicates
    self.fetchedResultsController.delegate = self; // If nil, explicitly call perform fetch (via Notification) to update list
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = BANYAN_GREEN_COLOR;
    [refreshControl addTarget:[BanyanConnection class] action:@selector(loadDataSource) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [self.tableView setRowHeight:TABLE_ROW_HEIGHT];
    
    self.filterStoriesSegmentedControl = [[UISegmentedControl alloc]
                                          initWithItems:[NSArray arrayWithObjects:@"Following", @"Popular", nil]];
    [self.filterStoriesSegmentedControl addTarget:self
                                           action:@selector(filterStories:)
                                 forControlEvents:UIControlEventValueChanged];
    self.filterStoriesSegmentedControl.tintColor = BANYAN_GREEN_COLOR;
    self.filterStoriesSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.filterStoriesSegmentedControl.selectedSegmentIndex = FilterStoriesSegmentIndexPopular;
    [self.filterStoriesSegmentedControl setWidth:100 forSegmentAtIndex:FilterStoriesSegmentIndexFollowing];
    [self.filterStoriesSegmentedControl setWidth:100 forSegmentAtIndex:FilterStoriesSegmentIndexPopular];
    [self.filterStoriesSegmentedControl setContentOffset:CGSizeMake(5, 0) forSegmentAtIndex:FilterStoriesSegmentIndexFollowing];
    [self.filterStoriesSegmentedControl setContentOffset:CGSizeMake(5, 0) forSegmentAtIndex:FilterStoriesSegmentIndexPopular];
    self.filterStoriesSegmentedControl.apportionsSegmentWidthsByContent = YES;
    
    [self.navigationItem setTitleView:self.filterStoriesSegmentedControl];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self action:@selector(addStoryOrPieceButtonPressed:)];
    self.navigationItem.rightBarButtonItem.tintColor = BANYAN_GREEN_COLOR;
    // Notifications to refresh data
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(filterStories:)
                                                 name:BNStoryListRefreshedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(foregroundRefresh:)
                                                 name:AFNetworkingReachabilityDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshStoryList:)
                                                 name:BNRefreshCurrentStoryListNotification
                                               object:nil];
    
    [TestFlight passCheckpoint:@"RootViewController loaded"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setFilterStoriesSegmentedControl:nil];
    self.fetchedResultsController = nil;
    self.indexOfVisibleBackView = nil;
    NSLog(@"Root View Controller Unloaded");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SingleStoryCell";
    SingleStoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[SingleStoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.delegate = self;
    [cell setStory:story];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Only if there is more than one section should we show the name
    return [[self.fetchedResultsController sections] count] > 1 ? 20 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = tableView.bounds;
    frame.size.height = [self tableView:tableView heightForHeaderInSection:section];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:frame];
    titleLabel.attributedText = [[NSAttributedString alloc] initWithString:[[[self.fetchedResultsController sections] objectAtIndex:section] name]
                                                                attributes:@{NSUnderlineStyleAttributeName: @1}];;
    titleLabel.font = [UIFont fontWithName:@"Roboto" size:15];
    titleLabel.textColor = BANYAN_BLACK_COLOR;
    titleLabel.minimumScaleFactor = 0.8;
    titleLabel.backgroundColor = BANYAN_LIGHTGRAY_COLOR;
    
    return titleLabel;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

#pragma mark Table View Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TABLE_ROW_HEIGHT;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (story.length) {
        return indexPath;
    } else {
        [self addPieceToStory:story];
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self readStoryForIndexPath:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [Story deleteStory:story];
        [TestFlight passCheckpoint:@"Story deleted by swipe"];
    }
}

- (void)addPieceForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self addPieceToStory:story];
}

- (void) shareStoryAtIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSLog(@"Sharing story: %@", story);
    assert(false);
}

#pragma mark StoryListCellDelegate
- (void) addPieceForSingleStoryCell:(SingleStoryCell *)cell
{
    NSIndexPath *myIndexPath = [self.tableView indexPathForCell:cell];
    [self addPieceForRowAtIndexPath:myIndexPath];
}

- (void) deleteStoryForSingleStoryCell:(SingleStoryCell *)cell
{
    NSIndexPath *myIndexPath = [self.tableView indexPathForCell:cell];
    [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:myIndexPath];
}

- (void) shareStoryForSingleStoryCell:(SingleStoryCell *)cell
{
    NSIndexPath *myIndexPath = [self.tableView indexPathForCell:cell];
    [self shareStoryAtIndexPath:myIndexPath];
}

#pragma mark Data Source Loading / Reloading Methods
- (void) refreshStoryList:(NSNotification *)notification
{
    if (!self.fetchedResultsController.delegate)
        [self performFetch];
    else
        [self.tableView reloadData];
}

// Called by both data source updated notification and by clicking on the filter segmented control
- (IBAction)filterStories:(id)sender
{
    [self filterStoriesForTableDataSource];
}

- (void) filterStoriesForTableDataSource
{
    [self.refreshControl endRefreshing];
    
    NSPredicate *predicate = nil;
    NSMutableArray *arrayOfUserIdsBeingFollowed = nil;
    
    switch (self.filterStoriesSegmentedControl.selectedSegmentIndex) {
        case FilterStoriesSegmentIndexPopular:
            predicate = [NSPredicate predicateWithFormat:@"(canView == YES) OR (canContribute == YES)"];
            break;
        case FilterStoriesSegmentIndexFollowing:
            arrayOfUserIdsBeingFollowed = [NSMutableArray array];
            for (NSMutableDictionary *user in [[NSUserDefaults standardUserDefaults]
                                               arrayForKey:BNUserDefaultsBanyanUsersFacebookFriends]) {
                if ([[user objectForKey:USER_BEING_FOLLOWED] boolValue]) {
                    [arrayOfUserIdsBeingFollowed addObject:[user objectForKey:@"id"]];
                }
            }
            // Create a predicate where author in arrayOfUserIdsBeingFollowed
            predicate = [NSPredicate predicateWithFormat:@"((canView == YES) OR (canContribute == YES)) AND ((author.userId IN %@))", arrayOfUserIdsBeingFollowed];
            break;
        default:
            break;
    }
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    [self performFetch];
}

-(void)foregroundRefresh:(NSNotification *)notification
{
    if ([notification.name isEqualToString:AFNetworkingReachabilityDidChangeNotification]) {
        // This is only for the initial part when the status of reachability is Unknown.
        // We don't want to keep getting this notification and refreshing the story table.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
        if (![[AFBanyanAPIClient sharedClient] isReachable]) {
            return;
        }
    }
    
    [BanyanConnection loadDataSource];
    [self.refreshControl beginRefreshing];
}


#pragma mark Story Manipulations
- (void) updateStoryInBackgroud:(Story *)story
{
    [BanyanConnection loadPiecesForStory:story completionBlock:^{
        NSLog(@"Pieces updated for story: %@ with title %@", story.bnObjectId, story.title);
    } errorBlock:^(NSError *error){
        NSLog(@"Error %@ when fetching pieces for story: %@ with title %@", [error localizedDescription], story.bnObjectId, story.title);
    }];
}

- (BOOL) updateStoryInForeground:(Story *)story
{
    // For RunLoop
    __block BOOL doneRun = NO;
    __block BOOL success = NO;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Fetching pieces for the story";
    hud.detailsLabelText = story.title;
    NSLog(@"Loading story pieces");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    [BanyanConnection loadPiecesForStory:story completionBlock:^{
        doneRun = YES;
        success = YES;
    } errorBlock:^(NSError *error){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to load the pieces for this story."
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        doneRun = YES;
        NSLog(@"Hit error: %@", error);
    }];
    
    do
    {
        // Start the run loop but return after each source is handled.
        SInt32    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, YES);
        
        // If a source explicitly stopped the run loop, or if there are no
        // sources or timers, go ahead and exit.
        if ((result == kCFRunLoopRunStopped) || (result == kCFRunLoopRunFinished))
            doneRun = YES;
        
        // Check for any other exit conditions here and set the
        // done variable as needed.
    }
    while (!doneRun);
    [hud hide:YES];
    
    return success;
}

-(void) readStoryForIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    SingleStoryCell *singleStoryCell = (SingleStoryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    Piece *pieceToShow = [singleStoryCell currentlyVisiblePiece];
    
    if (!pieceToShow) {
        [self.tableView reloadData];
        return;
    }
    StoryReaderController *storyReaderController = [[StoryReaderController alloc] initWithPiece:pieceToShow];
    storyReaderController.story = story;
    storyReaderController.hidesBottomBarWhenPushed = YES;
    storyReaderController.wantsFullScreenLayout = YES;
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:storyReaderController];
//    [self presentViewController:navController animated:YES completion:nil];
    [self.navigationController pushViewController:storyReaderController animated:YES];
}

-(void) addPieceToStory:(Story *)story
{
    if (![BanyanAppDelegate loggedIn] || !story.canContribute)
        return;
    
    Piece *piece = [Piece newPieceDraftForStory:story];
    ModifyPieceViewController *addPieceViewController = [[ModifyPieceViewController alloc] initWithPiece:piece];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPieceViewController];
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [navController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:navController animated:YES completion:nil];
}

-(IBAction) addStoryOrPieceButtonPressed:(UIButton *)sender
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![BanyanAppDelegate loggedIn]) {
        [delegate login];
    } else {
        // If there is already a default story user is creating a story on, use that story.
        // Else show the story picker view controller.
        
        Story *story = [Story getCurrentOngoingStoryToContribute];
        if (!story) {
            StoryPickerViewController *vc = [[StoryPickerViewController alloc] initWithStyle:UITableViewStylePlain];
            vc.delegate = self;
            UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nvc animated:YES completion:nil];
        } else {
            [self addPieceToStory:story];
        }
    }
}

# pragma mark StoryPickerViewControllerDelegate
- (void) storyPickerViewControllerDidPickStory:(Story *)story
{
    [self addPieceToStory:story];
}

#pragma mark - Swipeable controls

- (void)revealSwipedViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	[self hideVisibleSwipedView:animated];
	
	if ([cell respondsToSelector:@selector(revealSwipedViewAnimated:)]){
		[(SingleStoryCell *)cell revealSwipedViewAnimated:YES];
	}
    self.indexOfVisibleBackView = indexPath;
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height - scrollView.contentOffset.y < (self.view.bounds.size.height)) {
        if (![BanyanConnection storiesPaginator].objectRequestOperation && [[BanyanConnection storiesPaginator] isLoaded] && [[BanyanConnection storiesPaginator] hasNextPage]) {
            [[BanyanConnection storiesPaginator] loadNextPage];
        }
    }
}

- (void)hideVisibleSwipedView:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:self.indexOfVisibleBackView];
	if ([cell respondsToSelector:@selector(hideSwipedViewAnimated:)]) {
		[(SingleStoryCell *)cell hideSwipedViewAnimated:YES];
	}
    self.indexOfVisibleBackView = nil;
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
