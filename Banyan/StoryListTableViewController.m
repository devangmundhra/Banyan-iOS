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

@interface StoryListTableViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addStory;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *leftButton;
@property (weak, nonatomic) UserManagementModule *userManagementModule;
@end

@implementation StoryListTableViewController
@synthesize addStory = _addStory;
@synthesize leftButton = _leftButton;
@synthesize userManagementModule = _userManagementModule;
@synthesize dataSource = _dataSource;

- (NSMutableArray *)dataSource
{
    return [BanyanDataSource shared];
}

- (void)setDataSource:(NSMutableArray *)dataSource
{
    [[BanyanDataSource shared] setArray:dataSource];
}

- (UserManagementModule *)userManagementModule
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.userManagementModule.owningViewController = self;

    return delegate.userManagementModule;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.toolbarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
        self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" 
                                                           style:UIBarButtonItemStyleBordered 
                                                          target:self 
                                                          action:@selector(signout)];
    if (!self.addStory)
        self.addStory = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                      target:(self) 
                                                                      action:@selector(addStorySegue:)];
    // Notifications to handle permission controls
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged:) 
                                                 name:USER_MANAGEMENT_MODULE_USER_LOGIN_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userLoginStatusChanged:) 
                                                 name:USER_MANAGEMENT_MODULE_USER_LOGOUT_NOTIFICATION 
                                               object:nil];
    
    // Notifications to refresh data
    /*
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(foregroundRefresh:) 
                                                 name:UIApplicationWillEnterForegroundNotification 
                                               object:nil];
    */
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(foregroundRefresh:) 
                                                 name:UIApplicationDidFinishLaunchingNotification 
                                               object:nil];
    
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
    
    if (!self.dataSource) {
        // Get data from Parse and store it in Documents and StoryList
        // This is so that the user is not left waiting while stories are loaded from the network
        self.dataSource = [StoryDocuments loadStoriesFromDisk];
    }

    [self refreshView];
    
    [TestFlight passCheckpoint:@"RootViewController view loaded"];
}

- (void)refreshView
{
    self.leftButton.title = @"Sign out";
    self.leftButton.target = self;
    self.leftButton.action = @selector(signout);
    
    if ([self.userManagementModule isUserSignedIntoApp])
    {
        [self.navigationItem setLeftBarButtonItem:self.leftButton animated:YES];
        [self.navigationItem setRightBarButtonItem:self.addStory animated:YES];
    }
    else {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
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
    [super viewDidUnload];
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
    if (cell == nil)
        cell = [[StoryListStoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    // Configure the cell...
    Story *story = [self.dataSource objectAtIndex:indexPath.row];
    
    cell.storyTitleLabel.text = story.title;
    cell.storyTitleLabel.font = [UIFont fontWithName:STORY_FONT size:20];
    // So that the cell does not show any image from before
    cell.storyImageView.image = nil;
    [cell.storyImageView setImageWithURL:[NSURL URLWithString:story.imageURL] placeholderImage:story.image];
//    [cell.storyImageView setPathToNetworkImage:story.imageURL contentMode:UIViewContentModeScaleAspectFill];
    if (story.isLocationEnabled) {
        // add the location information about the cells
        cell.storyLocationLabel.text = story.geocodedLocation;
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.dataSource objectAtIndex:indexPath.row];
    if (!story.scenes)
    {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading";
        hud.detailsLabelText = story.title;

        NSLog(@"Loading story scenes");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
        [ParseConnection loadScenesForStory:story];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
    else {
        NSLog(@"Story scenes already loaded");
    }
    return indexPath;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Give the option to delete the story only if you are a contributor to the story too
    Story *story = [self.dataSource objectAtIndex:indexPath.row];
    return story.canContribute;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Story *story = [self.dataSource objectAtIndex:indexPath.row];
        [Story removeStory:story];
        [TestFlight passCheckpoint:@"Story deleted by swipe"];
    }    
}
#pragma mark Data Source Loading / Reloading Methods

- (void) loadDataSource
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(canView == YES) OR (canContribute == YES)"];
    
    [ParseConnection loadStoriesFromParseWithBlock:^(NSMutableArray *retValue){
        [retValue filterUsingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = retValue;
            [_pull refreshLastUpdatedDate];
            [self.tableView reloadData];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        });
    } 
                                      onCompletion:^{
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [_pull finishedLoading];  
                                          });
                                      }];
}

-(void)foregroundRefresh:(NSNotification *)notification
{
    self.tableView.contentOffset = CGPointMake(0, -65);
    [_pull setState:PullToRefreshViewStateLoading];
    [self performSelectorInBackground:@selector(loadDataSource) withObject:nil];
}

- (void)changeInStoryList:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    Story *story = [userInfo objectForKey:@"Story"];
    
    if ([notification.name isEqualToString:STORY_NEW_STORY_NOTIFICATION]){
        NSLog(@"%s %@ added", __PRETTY_FUNCTION__, story);
        [self.dataSource insertObject:story atIndex:0];
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
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    } else if ([notification.name isEqualToString:STORY_EDIT_STORY_NOTIFICATION]) {
        NSLog(@"%s %@ edit", __PRETTY_FUNCTION__, story);
        NSUInteger indexOfStory = [self. dataSource indexOfObject:story];
        if (indexOfStory == NSNotFound) {
            NSLog(@"%s Can't find story in the datasource", __PRETTY_FUNCTION__);
            return;
        }
        NSArray *editIndexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexOfStory inSection:0]];
        [self.dataSource replaceObjectAtIndex:indexOfStory withObject:story];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:editIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

# pragma mark - segues

- (IBAction)addStorySegue:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"New Story" sender:nil];
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
    [self refreshView];
}

#pragma mark User Account controls
- (void) signout
{
    [self.userManagementModule logout];
}

- (void) userLoginStatusChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:USER_MANAGEMENT_MODULE_USER_LOGOUT_NOTIFICATION]) {
        [ParseConnection resetPermissionsForStories:self.dataSource];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(canView == YES) OR (canContribute == YES)"];
        [self.dataSource filterUsingPredicate:predicate];
        [self.tableView reloadData];
        [self refreshView];
    } else if ([[notification name] isEqualToString:USER_MANAGEMENT_MODULE_USER_LOGIN_NOTIFICATION]) {
        [self loadDataSource];
        [self refreshView];
    } else {
        NSLog(@"%s Unknown notification %@", __PRETTY_FUNCTION__, [notification name]);
    }
}

#pragma PullToRefreshView delegate methods
// called when the user pulls-to-refresh
- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view
{
    [self performSelectorInBackground:@selector(loadDataSource) withObject:nil];
}
// called when the date shown needs to be updated, optional
-(NSDate *)pullToRefreshViewLastUpdated:(PullToRefreshView *)view
{
    return [NSDate date];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    [self.tableView removeObserver:_pull forKeyPath:@"contentOffset"];
    
    // Release all the scene information from the stories. This can be added later
    for (Story *story in self.dataSource) {
        story.scenes = nil;
    }
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
