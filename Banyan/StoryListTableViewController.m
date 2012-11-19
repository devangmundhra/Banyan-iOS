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
@end

@implementation StoryListTableViewController
@synthesize addStory = _addStory;
@synthesize leftButton = _leftButton;
@synthesize userManagementModule = _userManagementModule;
@synthesize filterStoriesSegmentedControl = _filterStoriesSegmentedControl;
@synthesize dataSource = _dataSource;

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

    if (!_pull)
        _pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *)self.tableView];
    [_pull setDelegate:self];
    [self.tableView addSubview:_pull];
    
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
    _pull = nil;
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
    
    cell.storyTitleLabel.text = story.title;
    cell.storyTitleLabel.font = [UIFont fontWithName:STORY_FONT size:20];
    
    if (story.imageURL) {
        cell.storyTitleLabel.textColor = [UIColor whiteColor];
        cell.storyLocationLabel.textColor = [UIColor whiteColor];
    } else {
        cell.storyTitleLabel.textColor = [UIColor blackColor];
        cell.storyLocationLabel.textColor = [UIColor grayColor];
    }

    CGSize cellImageSize = cell.storyImageView.frame.size;
    if (story.imageURL && [story.imageURL rangeOfString:@"asset"].location == NSNotFound) {
        [cell.storyImageView setImageWithURL:[NSURL URLWithString:story.imageURL] placeholderImage:story.image];
        NSURLRequest *imageReq = [NSURLRequest requestWithURL:[NSURL URLWithString:story.imageURL]];
        
        [cell.storyImageView setImageWithURLRequest:imageReq
                                   placeholderImage:story.image
                                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                                                    bounds:cellImageSize
                                                                      interpolationQuality:kCGInterpolationHigh];
                                            }
                                            failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                NSLog(@"***** ERROR IN GETTING IMAGE ***\nCan't find the image");
                                            }];
    } else if (story.imageURL) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:story.imageURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullScreenImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                bounds:cellImageSize
                                  interpolationQuality:kCGInterpolationHigh];
            [cell.storyImageView setImage:image];
        }
                failureBlock:^(NSError *error) {
                    NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
                }
         ];
    }

    if (story.isLocationEnabled && ![story.geocodedLocation isEqual:[NSNull null]]) {
        // add the location information about the cells
        cell.storyLocationLabel.text = story.geocodedLocation;
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
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

#pragma mark Data Source Loading / Reloading Methods
// Called by both data source updated notification and by clicking on the filter segmented control
- (IBAction)filterStories:(id)sender
{
    [self filterStoriesForTableDataSource];
}

- (void) filterStoriesForTableDataSource
{
    [_pull finishedLoading];
    
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
    [_pull setState:PullToRefreshViewStateLoading];
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
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    if ([segue.identifier isEqualToString:@"New Story"])
    {
        NewStoryViewController *newStoryViewController = segue.destinationViewController;
        newStoryViewController.delegate = self;

    } else if ([segue.identifier isEqualToString:@"Read Story"])
    {
        Story *selectedStory = nil;
        if ([sender isKindOfClass:[Story class]])
            selectedStory = sender;
        else
            selectedStory = [self.dataSource objectAtIndex:indexPath.row];
        ScenesViewController *scenesViewController = segue.destinationViewController;
        scenesViewController.story = selectedStory;
        scenesViewController.delegate = self;
        [scenesViewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    }
    else if ([segue.identifier isEqualToString:@"Sign In"])
    {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark - NewStoryViewControllerDelegate

- (void) newStoryViewController:(NewStoryViewController *)sender 
                    didAddStory:(Story *)story
{
    [self.navigationController popViewControllerAnimated:NO];
    [self performSegueWithIdentifier:@"Read Story" sender:story];
}

#pragma mark ScenesViewControllerDelegate
- (void)scenesViewContollerDone:(ScenesViewController *)scenesViewController
{
    [self.navigationController popViewControllerAnimated:YES];
    scenesViewController.story.storyBeingRead = NO;
    [self refreshView];
}

#pragma PullToRefreshView delegate methods
// called when the user pulls-to-refresh
- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view
{
    [[BanyanDataSource class] performSelectorInBackground:@selector(loadDataSource) withObject:nil];
}

// called when the date shown needs to be updated, optional
- (NSDate *)pullToRefreshViewLastUpdated:(PullToRefreshView *)view
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
