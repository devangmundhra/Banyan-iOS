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


typedef enum {
    FilterStoriesSegmentIndexPopular = 0,
    FilterStoriesSegmentIndexFollowing,
    FilterStoriesSegmentIndexInvited
} FilterStoriesSegmentIndex;

@interface StoryListTableViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addStory;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *leftButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *filterStoriesSegmentedControl;
@end

@implementation StoryListTableViewController
@synthesize addStory = _addStory;
@synthesize leftButton = _leftButton;
@synthesize filterStoriesSegmentedControl = _filterStoriesSegmentedControl;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationNone];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.toolbarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [self refreshView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [self setEditing:NO animated:YES];
    [self.tableView setEditing:NO animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [[BanyanConnection class] performSelectorInBackground:@selector(loadDataSource) withObject:nil];
    }];
    
    [self.tableView setRowHeight:TABLE_ROW_HEIGHT];
    
    if (!self.leftButton)
        self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" 
                                                           style:UIBarButtonItemStyleBordered 
                                                          target:self 
                                                          action:@selector(settings)];
    if (!self.addStory)
        self.addStory = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                      target:(self) 
                                                                      action:@selector(addStorySegue:)];
    
    if (!self.filterStoriesSegmentedControl) {
        self.filterStoriesSegmentedControl = [[UISegmentedControl alloc]
                                              initWithItems:[NSArray arrayWithObjects:@"Popular", @"Following", @"Invited", nil]];
        [self.filterStoriesSegmentedControl addTarget:self
                                               action:@selector(filterStories:)
                                     forControlEvents:UIControlEventValueChanged];
        self.filterStoriesSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        self.filterStoriesSegmentedControl.selectedSegmentIndex = FilterStoriesSegmentIndexPopular;
        self.filterStoriesSegmentedControl.apportionsSegmentWidthsByContent = YES;
    }

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
    
    [TestFlight passCheckpoint:@"RootViewController view loaded"];
}

- (void)refreshView
{
    self.leftButton.title = @"Settings";
    self.leftButton.target = self;
    self.leftButton.action = @selector(settings);
    [self.navigationItem setLeftBarButtonItem:self.leftButton animated:YES];

    UserManagementModule *userManagementModule = [(BanyanAppDelegate *)[[UIApplication sharedApplication] delegate] userManagementModule];

    if ([userManagementModule isUserSignedIntoApp])
    {
        [self.navigationItem setRightBarButtonItem:self.addStory animated:YES];
        [self.navigationItem setTitleView:self.filterStoriesSegmentedControl];
    }
    else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.navigationItem setTitle:@"Banyan"];
        [self.navigationItem setTitleView:nil];
    }

    // Reset the content context so any unwanted changes are not saved.
    // The changes that are needed (like create/edit/etc..) should have got saved anyways.
    [BANYAN_USER_CONTENT_MANAGED_OBJECT_CONTEXT reset];
    
    // Don't reload data here as it is called everytime it comes back from sceneviewcontroller
}

- (void)viewDidUnload
{
    [self setAddStory:nil];
    [self setLeftButton:nil];
    [self setAddStory:nil];
    [self setLeftButton:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self setFilterStoriesSegmentedControl:nil];
    self.fetchedResultsController = nil;
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
    StoryListStoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[StoryListStoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"Title being printed: %@", story.title);
    [cell setStory:story];
    
    return cell;
}

#pragma mark Table View Delegates
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![super tableView:tableView willSelectRowAtIndexPath:indexPath])
        return nil;
    
    return [self updateStoryAtIndex:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Story *selectedStory = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self readStory:selectedStory];
    
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
    // Give the option to delete the story only if you are a contributor to the story too
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return [story.canContribute boolValue];
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

- (void)addSceneForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self updateStoryAtIndex:indexPath]) {
        Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self addSceneToStory:story];
    }
}



#pragma mark TISwipeableTableView delegates
- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	
	[super tableView:tableView didSwipeCellAtIndexPath:indexPath];
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
            // Create a predicate where author.userId in arrayOfUserIdsBeingFollowed
            predicate = [NSPredicate predicateWithFormat:@"((canView == YES) OR (canContribute == YES)) AND ((author.userId IN %@))", arrayOfUserIdsBeingFollowed];
            break;
        case FilterStoriesSegmentIndexInvited:
            predicate = [NSPredicate predicateWithFormat:@"(isInvited == YES)"];
            break;
        default:
            break;
    }

    NSError *error = nil;
    self.fetchedResultsController.fetchRequest.predicate = predicate;
	if (![[self fetchedResultsController] performFetch:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
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

# pragma mark - segues
- (void) settings
{
    SettingsTableViewController *vc = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)addStorySegue:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"New Story" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"New Story"])
    {
        NewStoryViewController *newStoryViewController = segue.destinationViewController;
        newStoryViewController.delegate = self;

    }
    else if ([segue.identifier isEqualToString:@"Sign In"])
    {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark Story Manipulations
- (NSIndexPath *) updateStoryAtIndex:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    story.storyBeingRead = [NSNumber numberWithBool:YES];

    if (!story.pieces.count)
    {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Fetching pieces for the story";
        hud.detailsLabelText = story.title;
        NSLog(@"Loading story pieces");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
        [BanyanConnection loadPiecesForStory:story completionBlock:^{
            if ([story.length integerValue]) {
                assert(story.pieces.count);
                [self readStory:story];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }
            else {
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"No pieces found for the story!";
                [hud hide:YES afterDelay:2];
            }
        } errorBlock:^(NSError *error){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to load the pieces for this story."
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            NSLog(@"Hit error: %@", error);
        }];
        return nil;
    }
    return indexPath;
}

-(void) readStory:(Story *)story
{
    StoryReaderController *storyReaderController = [[StoryReaderController alloc] init];
    storyReaderController.story = story;
    storyReaderController.delegate = self;
    [storyReaderController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self.navigationController pushViewController:storyReaderController animated:YES];
}

-(void) addSceneToStory:(Story *)story
{
    ModifySceneViewController *addSceneViewController = [[ModifySceneViewController alloc] init];
    addSceneViewController.editMode = add;
    Piece *piece = [NSEntityDescription insertNewObjectForEntityForName:kBNPieceClassKey
                                                 inManagedObjectContext:BANYAN_USER_CONTENT_MANAGED_OBJECT_CONTEXT];
    piece.story = story;
    addSceneViewController.piece = piece;
    addSceneViewController.editMode = add;
    addSceneViewController.delegate = self;
    [addSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [addSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:addSceneViewController animated:YES completion:nil];
}


#pragma mark ModifySceneViewControllerDelegate

- (void) modifySceneViewController:(ModifySceneViewController *)controller
              didFinishAddingScene:(Piece *)scene
{
    NSLog(@"StoryListTableViewController_Adding scene");
    [self dismissViewControllerAnimated:NO completion:^{
        [self hideVisibleBackView:YES];
    }];
}

- (void) modifySceneViewControllerDidCancel:(ModifySceneViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NewStoryViewControllerDelegate

- (void) newStoryViewController:(NewStoryViewController *)sender 
                    didAddStory:(Story *)story
{
    [self.navigationController popViewControllerAnimated:NO];
    [self addSceneToStory:story];
}

#pragma mark ScenesViewControllerDelegate
- (void)storyReaderContollerDone:(StoryReaderController *)scenesViewController
{
    [self.navigationController popViewControllerAnimated:YES];
    scenesViewController.story.storyBeingRead = NO;
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
