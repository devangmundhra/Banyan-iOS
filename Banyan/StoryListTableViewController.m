//
//  StoryListTableViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryListTableViewController.h"
#import "ParseConnection.h"
#import "StoryDocuments.h"
#import "BanyanAppDelegate.h"
#import "BanyanPullToRefreshContentView.h"

typedef enum {
    FilterStoriesSegmentIndexPopular = 0,
    FilterStoriesSegmentIndexFollowing,
    FilterStoriesSegmentIndexInvited
} FilterStoriesSegmentIndex;

@interface StoryListTableViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addStory;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *leftButton;
@property (weak, nonatomic) UserManagementModule *userManagementModule;
@property (strong, nonatomic) IBOutlet UISegmentedControl *filterStoriesSegmentedControl;
@property (strong, nonatomic) SSPullToRefreshView *pullToRefreshView;
@end

@implementation StoryListTableViewController
@synthesize addStory = _addStory;
@synthesize leftButton = _leftButton;
@synthesize userManagementModule = _userManagementModule;
@synthesize filterStoriesSegmentedControl = _filterStoriesSegmentedControl;
@synthesize dataSource = _dataSource;
@synthesize pullToRefreshView = _pullToRefreshView;

- (UserManagementModule *)userManagementModule
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.userManagementModule.owningViewController = self;

    return delegate.userManagementModule;
}

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
    
    // Frame size for content view. We need a big frame so that as we keep pulling the scrollview, we
    // see the same background colour.
    CGRect pullContentViewFrame =  self.tableView.frame;
    pullContentViewFrame.origin.y = 0.0f - pullContentViewFrame.size.height;
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
    self.pullToRefreshView.contentView = [[BanyanPullToRefreshContentView alloc] initWithFrame:pullContentViewFrame];
    
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
    
    // Notifications to refresh data
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(filterStories:)
                                                 name:BNDataSourceUpdatedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(foregroundRefresh:)
                                                 name:AFNetworkingReachabilityDidChangeNotification
                                               object:nil];
    
    /*
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(foregroundRefresh:) 
                                                 name:UIApplicationDidFinishLaunchingNotification 
                                               object:nil];
    */
    // Notifications when story list modified
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changeInStoryList:) 
                                                 name:STORY_NEW_STORY_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changeInStoryList:) 
                                                 name:STORY_DELETE_STORY_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changeInStoryList:) 
                                                 name:STORY_EDIT_STORY_NOTIFICATION
                                               object:nil];

    self.dataSource = [NSMutableArray array];
    
    [TestFlight passCheckpoint:@"RootViewController view loaded"];
}

- (void)refreshView
{
    self.leftButton.title = @"Settings";
    self.leftButton.target = self;
    self.leftButton.action = @selector(settings);
    [self.navigationItem setLeftBarButtonItem:self.leftButton animated:YES];

    if ([self.userManagementModule isUserSignedIntoApp])
    {
        [self.navigationItem setRightBarButtonItem:self.addStory animated:YES];
        [self.navigationItem setTitleView:self.filterStoriesSegmentedControl];
    }
    else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.navigationItem setTitle:@"Banyan"];
        [self.navigationItem setTitleView:nil];
    }

    // Don't reload data here as it is called everytime it comes back from sceneviewcontroller
}

- (void)viewDidUnload
{
    [self setAddStory:nil];
    [self setUserManagementModule:nil];
    [self setLeftButton:nil];
    [self setAddStory:nil];
    [self setLeftButton:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.pullToRefreshView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self setFilterStoriesSegmentedControl:nil];
    [super viewDidUnload];
    NSLog(@"Root View Controller Unloaded");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Story Cell";
    StoryListStoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[StoryListStoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    Story *story = [self.dataSource objectAtIndex:indexPath.row];
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
    
    Story *selectedStory = [self.dataSource objectAtIndex:indexPath.row];
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
    Story *story = [self.dataSource objectAtIndex:indexPath.row];
    return story.canContribute;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Story *story = [self.dataSource objectAtIndex:indexPath.row];
        DELETE_STORY(story);
        [TestFlight passCheckpoint:@"Story deleted by swipe"];
    }    
}

- (void)addSceneForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self updateStoryAtIndex:indexPath]) {
        Story *story = [self.dataSource objectAtIndex:indexPath.row];
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
    [self.pullToRefreshView finishLoading];
    
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

    [self.dataSource setArray:[BanyanDataSource shared]];
    [self.dataSource filterUsingPredicate:predicate];
    [self.tableView reloadData];
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
    self.tableView.contentOffset = CGPointMake(0, -65);
    [self.pullToRefreshView startLoading];
    [[BanyanDataSource class] performSelectorInBackground:@selector(loadDataSource) withObject:nil];
}

- (void)changeInStoryList:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    Story *story = [userInfo objectForKey:@"Story"];
    
    if ([notification.name isEqualToString:STORY_NEW_STORY_NOTIFICATION]) {
        NSLog(@"%s %@ added", __PRETTY_FUNCTION__, story);
        [self.dataSource insertObject:story atIndex:0];
        [[BanyanDataSource shared] insertObject:story atIndex:0];
        NSArray *insertIndexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
    } else if ([notification.name isEqualToString:STORY_DELETE_STORY_NOTIFICATION]) {
        NSLog(@"%s %@ delete", __PRETTY_FUNCTION__, story);
        NSUInteger indexOfStory = [self. dataSource indexOfObject:story];
        if (indexOfStory == NSNotFound) {
            NSLog(@"%s Can't find story in the datasource", __PRETTY_FUNCTION__);
            return;
        }
        NSArray *deleteIndexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexOfStory inSection:0]];
        [self.dataSource removeObject:story];
        [[BanyanDataSource shared] removeObject:story];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    } else if ([notification.name isEqualToString:STORY_EDIT_STORY_NOTIFICATION]) {
        NSLog(@"%s %@ edit", __PRETTY_FUNCTION__, story);
        NSUInteger indexOfStory = [self.dataSource indexOfObject:story];
        if (indexOfStory == NSNotFound) {
            NSLog(@"%s Can't find story in the datasource", __PRETTY_FUNCTION__);
            return;
        }
        NSArray *editIndexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexOfStory inSection:0]];
        [self.dataSource replaceObjectAtIndex:indexOfStory withObject:story];
        [[BanyanDataSource shared] replaceObjectAtIndex:[[BanyanDataSource shared] indexOfObject:story] withObject:story];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:editIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
    [self filterStoriesForTableDataSource];
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
//    NewStoryViewController *newStoryViewController = [[NewStoryViewController alloc] init];
//    newStoryViewController.delegate = self;
//    [self.navigationController pushViewController:newStoryViewController animated:YES];
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
    Story *story = [self.dataSource objectAtIndex:indexPath.row];
    story.storyBeingRead = YES;
    UIAlertView *networkUnavailableAlert = [[UIAlertView alloc] initWithTitle:@"Network unavailable"
                                                                      message:@"We are unable to access the network and so can't load the story"
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
    if (!story.scenes)
    {
        Story *alreadyExistingStory = [StoryDocuments loadStoryFromDisk:story.storyId];
        alreadyExistingStory.storyBeingRead = YES;
        if (alreadyExistingStory) {
            // If a story is already existing, load that story.
            [[BanyanDataSource shared] replaceObjectAtIndex:[[BanyanDataSource shared] indexOfObject:story] withObject:alreadyExistingStory];
            [self.dataSource replaceObjectAtIndex:indexPath.row withObject:alreadyExistingStory];
        } else {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = @"Loading";
            hud.detailsLabelText = story.title;
            NSLog(@"Loading story scenes");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
            [ParseConnection loadScenesForStory:story];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
        
    }
    if (!story.scenes || [story.scenes count] == 0) {
        NSLog(@"%s story.scenes %@ story count: %d", __PRETTY_FUNCTION__, story.scenes, [story.scenes count]);
        [networkUnavailableAlert show];
        return nil;
    }
    return indexPath;
}

-(void) readStory:(Story *)story
{
    ScenesViewController *scenesViewController = [[ScenesViewController alloc] init];
    scenesViewController.story = story;
    scenesViewController.delegate = self;
    [scenesViewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self.navigationController pushViewController:scenesViewController animated:YES];
}

-(void) addSceneToStory:(Story *)story
{
    ModifySceneViewController *addSceneViewController = [[ModifySceneViewController alloc] init];
    addSceneViewController.editMode = add;
    addSceneViewController.scene = [story.scenes lastObject];
    addSceneViewController.delegate = self;
    [addSceneViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [addSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:addSceneViewController animated:YES completion:nil];
}


#pragma mark ModifySceneViewControllerDelegate

- (void) modifySceneViewController:(ModifySceneViewController *)controller
              didFinishAddingScene:(Scene *)scene
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
    [self readStory:story];
}

#pragma mark ScenesViewControllerDelegate
- (void)scenesViewContollerDone:(ScenesViewController *)scenesViewController
{
    [self.navigationController popViewControllerAnimated:YES];
    scenesViewController.story.storyBeingRead = NO;
    [self refreshView];
}

#pragma SSPullToRefreshView delegate methods
// called when the user pulls-to-refresh
- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view
{
    [[BanyanDataSource class] performSelectorInBackground:@selector(loadDataSource) withObject:nil];
}

// called when the date shown needs to be updated, optional
- (NSDate *)pullToRefreshViewLastUpdatedAt:(SSPullToRefreshView *)view
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:BNUserDefaultsLastSuccessfulStoryUpdateTime];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Release all the scene information from the stories. This can be added later
    /*
    for (Story *story in [BanyanDataSource shared]) {
        if (!story.storyBeingRead && story.initialized && [[BNOperationQueue shared] operationCount] == 0) {
            story.scenes = nil;
            NSLog(@"Scenes for story %@ are nulled", story.storyId);
        }
    }
     */
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
