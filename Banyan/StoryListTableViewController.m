//
//  StoryListTableViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryListTableViewController.h"
#import "BanyanAppDelegate.h"
#import "SVPullToRefresh.h"
#import "StoryListCell.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    [self.tableView setBackgroundColor:[UIColor lightGrayColor]];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"StoryListCell" bundle:nil] forCellReuseIdentifier:@"Story Cell"];
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [[BanyanConnection class] performSelectorInBackground:@selector(loadDataSource) withObject:nil];
    }];
    
    [self.tableView setRowHeight:TABLE_ROW_HEIGHT];
    
    self.filterStoriesSegmentedControl = [[UISegmentedControl alloc]
                                          initWithItems:[NSArray arrayWithObjects:@"Following", @"Popular", nil]];
    [self.filterStoriesSegmentedControl addTarget:self
                                           action:@selector(filterStories:)
                                 forControlEvents:UIControlEventValueChanged];
    self.filterStoriesSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.filterStoriesSegmentedControl.selectedSegmentIndex = FilterStoriesSegmentIndexPopular;
    self.filterStoriesSegmentedControl.apportionsSegmentWidthsByContent = YES;

    [self.navigationItem setTitleView:self.filterStoriesSegmentedControl];
    
    // Fetched results controller
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kBNStoryClassKey];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"updatedAt"
                                                                                     ascending:YES
                                                                                      selector:@selector(compare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
    
    // Notifications to refresh data
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(filterStories:)
                                                 name:BNStoryListRefreshedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(foregroundRefresh:)
                                                 name:AFNetworkingReachabilityDidChangeNotification
                                               object:nil];
    
//    self.indexOfVisibleBackView = [[NSIndexPath alloc] init];
    [TestFlight passCheckpoint:@"RootViewController view loaded"];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setFilterStoriesSegmentedControl:nil];
    self.fetchedResultsController = nil;
    self.indexOfVisibleBackView = nil;
    [super viewDidUnload];
    NSLog(@"Root View Controller Unloaded");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Story Cell";
    StoryListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"StoryListCell" owner:self options:nil];
        cell = (StoryListCell *)[nibs objectAtIndex:0];
    }
    
    // Configure the cell...
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    [self updateStoryAtIndex:indexPath];
    [cell setStory:story];
    
    return cell;
}

#pragma mark Table View Delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    return [self updateStoryAtIndex:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Story *selectedStory = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self readStory:selectedStory];
    
    [self hideVisibleSwipedView:YES];
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
    [self updateStoryAtIndex:indexPath];
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self addPieceToStory:story];
}

- (void) shareStoryAtIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"Sharing story: %@", story);
    assert(false);
}

#pragma mark Data Source Loading / Reloading Methods
// Called by both data source updated notification and by clicking on the filter segmented control
- (IBAction)filterStories:(id)sender
{
    [self filterStoriesForTableDataSource];
}

- (void) filterStoriesForTableDataSource
{
    [self.tableView.pullToRefreshView stopAnimating];
    
    NSPredicate *predicate = nil;
    NSMutableArray *arrayOfUserIdsBeingFollowed = nil;
    
    switch (self.filterStoriesSegmentedControl.selectedSegmentIndex) {
        case FilterStoriesSegmentIndexPopular:
            predicate = [NSPredicate predicateWithFormat:@"(canView == YES) OR (canContribute == YES)"];
            break;
        case FilterStoriesSegmentIndexFollowing:
            arrayOfUserIdsBeingFollowed = [NSMutableArray array];
            for (NSMutableDictionary *user in [[NSUserDefaults standardUserDefaults]
                 objectForKey:BNUserDefaultsBanyanUsersFacebookFriends]) {
                if ([[user objectForKey:USER_BEING_FOLLOWED] boolValue]) {
                    [arrayOfUserIdsBeingFollowed addObject:[user objectForKey:@"objectId"]];
                }
            }
            // Create a predicate where author in arrayOfUserIdsBeingFollowed
            predicate = [NSPredicate predicateWithFormat:@"((canView == YES) OR (canContribute == YES)) AND ((author IN %@))", arrayOfUserIdsBeingFollowed];
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
        if (![[AFParseAPIClient sharedClient] isReachable]) {
            return;
        }
    }
    
    [self.tableView triggerPullToRefresh];
}


#pragma mark Story Manipulations
- (NSIndexPath *) updateStoryAtIndex:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (!story.pieces.count)
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
        
        // Come here after above block has been completed
        if ([story.length integerValue] && success) {
            assert(story.pieces.count);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            return indexPath;
        }
        else {
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"No pieces found for the story!";
            [hud hide:YES afterDelay:2];
            return nil;
        }
    }
    return indexPath;
}

-(void) readStory:(Story *)story
{
    story.storyBeingRead = [NSNumber numberWithBool:YES];
    StoryReaderController *storyReaderController = [[StoryReaderController alloc] init];
    storyReaderController.story = story;
    storyReaderController.delegate = self;
    [storyReaderController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self.navigationController pushViewController:storyReaderController animated:YES];
}

-(void) addPieceToStory:(Story *)story
{
    Piece *piece = [Piece newPieceDraftForStory:story];
    ModifyPieceViewController *addSceneViewController = [[ModifyPieceViewController alloc] initWithPiece:piece];
    [addSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [addSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:addSceneViewController animated:YES completion:nil];
}

#pragma mark - Swipeable controls

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self hideVisibleSwipedView:YES];
}

- (void)revealSwipedViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	[self hideVisibleSwipedView:animated];
	
	if ([cell respondsToSelector:@selector(revealSwipedViewAnimated:)]){
		[(StoryListCell *)cell revealSwipedViewAnimated:YES];
        [self setIndexOfVisibleBackView:indexPath];
	}
    self.indexOfVisibleBackView = indexPath;
}

- (void)hideVisibleSwipedView:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:self.indexOfVisibleBackView];
	if ([cell respondsToSelector:@selector(hideSwipedViewAnimated:)]) {
		[(StoryListCell *)cell hideSwipedViewAnimated:YES];
        [self setIndexOfVisibleBackView:nil];
	}
    self.indexOfVisibleBackView = nil;
}

#pragma mark ScenesViewControllerDelegate
- (void)storyReaderContollerDone:(StoryReaderController *)scenesViewController
{
    [self.navigationController popViewControllerAnimated:YES];
    scenesViewController.story.storyBeingRead = NO;
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
