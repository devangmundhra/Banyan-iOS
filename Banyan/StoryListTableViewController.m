//
//  StoryListTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
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
#import "CEFlipAnimationController.h"
#import "BNHorizontalSwipeInteractionController.h"
#import "ModifyPieceViewController.h"
#import "User.h"
#import "UIViewController+BNSlidingViewControllerAdditions.h"
#import "Story+Share.h"
#import "CMPopTipView.h"

static NSString *CellIdentifier = @"SingleStoryCell";

typedef enum {
    FilterStoriesSegmentIndexFollowing = 0,
    FilterStoriesSegmentIndexPopular
} FilterStoriesSegmentIndex;

@interface StoryListTableViewController (MYIntroductionDelegate) <MYIntroductionDelegate>
@end

@interface StoryListTableViewController (StoryReaderControllerDelegate) <StoryReaderControllerDelegate>
@end

@interface StoryListTableViewController () <UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) CEFlipAnimationController *animationController;
@property (strong, nonatomic) BNHorizontalSwipeInteractionController *interactionController;
@property (strong, nonatomic) UIButton *endOfStoryButton;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@end

@implementation StoryListTableViewController

@synthesize endOfStoryButton = _endOfStoryButton;
@synthesize activityView = _activityView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Animation between view controllers
    self.animationController = [[CEFlipAnimationController alloc] init];
    self.interactionController = [[BNHorizontalSwipeInteractionController alloc] init];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    self.navigationController.navigationBar.translucent = YES;
    
    self.title = @"Your Stories";
    
    [self.tableView registerClass:[SingleStoryCell class] forCellReuseIdentifier:CellIdentifier];
    [self.view setBackgroundColor:BANYAN_LIGHTGRAY_COLOR];
    [self.tableView setSeparatorColor:BANYAN_LIGHTGRAY_COLOR];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.tableView setShowsHorizontalScrollIndicator:NO];
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    // Fetched results controller
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kBNStoryClassKey];
    NSSortDescriptor *timeStampSD = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO];
    request.sortDescriptors = [NSArray arrayWithObjects:timeStampSD, nil];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil]; // Adding cache causes issues in filtering after changing predicates
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(canView == YES) OR (canContribute == YES)"];
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    self.fetchedResultsController.delegate = self; // If nil, explicitly call perform fetch (via Notification) to update list
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = BANYAN_GREEN_COLOR;
    [refreshControl addTarget:self action:@selector(refreshStoryList:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [self.tableView setRowHeight:TABLE_ROW_HEIGHT];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, CGRectGetHeight(self.navigationController.navigationBar.frame))];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = BANYAN_CLEAR_COLOR;
    titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.title
                                                                attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:20]}];
    self.navigationItem.titleView = titleLabel;
    if ([BanyanAppDelegate loggedIn]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"banyan_tinted"]
                                                                                  style:UIBarButtonItemStylePlain target:self
                                                                                 action:@selector(addStoryOrLoginButtonPressed:)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign in" style:UIBarButtonItemStylePlain target:self action:@selector(addStoryOrLoginButtonPressed:)];
    }

    self.navigationItem.rightBarButtonItem.tintColor = BANYAN_GREEN_COLOR;

    self.endOfStoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.endOfStoryButton.frame = CGRectMake(0, 10, CGRectGetWidth(self.view.frame), 100);
    self.endOfStoryButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.endOfStoryButton setTitleColor:BANYAN_BLACK_COLOR forState:UIControlStateNormal];
    self.endOfStoryButton.exclusiveTouch = YES;
    self.endOfStoryButton.titleLabel.minimumScaleFactor = 0.7;
    [self.endOfStoryButton addTarget:self action:@selector(endOfStoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityView startAnimating];
    
    self.tableView.tableFooterView = self.activityView;
    
    [self prepareForSlidingViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(filterStories:)
                                                 name:BNStoryListRefreshedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStoryList:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogInNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogOutNotification
                                               object:nil];
    
    // Don't need these notifications as FRC delegate will take care of it.
    if (!self.fetchedResultsController.delegate) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshStoryList:)
                                                     name:BNRefreshCurrentStoryListNotification
                                                   object:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Story List screen"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *firstTimeDict = [[defaults dictionaryForKey:BNUserDefaultsFirstTimeActionsDict] mutableCopy];
    BOOL appAlreadyOpened = [[firstTimeDict objectForKey:BNUserDefaultsFirstTimeAppOpen] boolValue];
    if (!appAlreadyOpened) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        BNIntroductionView *introductionView = [[BNIntroductionView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        introductionView.delegate = self;
        [self.navigationController.view addSubview:introductionView];
    }
    
    if (appAlreadyOpened && ![firstTimeDict objectForKey:BNUserDefaultsFirstTimeStoryListVCWSignin] && [BanyanAppDelegate loggedIn]) {
        [firstTimeDict setObject:[NSNumber numberWithBool:YES] forKey:BNUserDefaultsFirstTimeStoryListVCWSignin];
        [defaults setObject:firstTimeDict forKey:BNUserDefaultsFirstTimeActionsDict];
        [defaults synchronize];
        CMPopTipView *popTipView = [[CMPopTipView alloc] initWithMessage:@"Tap here to create new stories, or contribute to existing ones!"];
        SET_CMPOPTIPVIEW_APPEARANCES(popTipView);
        [popTipView presentPointingAtBarButtonItem:self.navigationItem.rightBarButtonItem animated:NO];
    }
}

- (void)dealloc
{
    BNLogInfo(@"StoryList View Controller Deallocated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) userLoginStatusChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:BNUserLogOutNotification]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign in" style:UIBarButtonItemStylePlain target:self action:@selector(addStoryOrLoginButtonPressed:)];
    } else if ([[notification name] isEqualToString:BNUserLogInNotification]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"banyan_tinted"]
                                                                                  style:UIBarButtonItemStylePlain target:self
                                                                                 action:@selector(addStoryOrLoginButtonPressed:)];
    } else {
        BNLogError(@"Unknown notification %@", [notification name]);
    }
    self.navigationItem.rightBarButtonItem.tintColor = BANYAN_GREEN_COLOR;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        [Story deleteStory:story completion:nil];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"delete by swipe" label:@"swipe_delete" value:nil];
    }
}

#pragma mark StoryListCellDelegate
- (void) addPieceForStory:(Story *)story
{
    [self addPieceToStory:story];
}

- (void) flagStory:(Story *)story withMessage:(NSString *)message
{
    [story flaggedWithMessage:message];
}

- (void) shareStory:(Story *)story
{
    [story shareOnFacebook];
}

- (void) hideStory:(Story *)story
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];

    if (currentUser) {
        [[AFBanyanAPIClient sharedClient] postPath:@"hide_object/"
                                        parameters:@{@"content_object":story.resourceUri}
                                           success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                               BNLogInfo(@"Story successfully hidden");
                                               [story remove];
                                           }
                                           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                               [BNMisc sendGoogleAnalyticsError:error inAction:@"Hide Story" isFatal:NO];
                                               BNLogError(@"An error occurred: %@", error.localizedDescription);
                                           }];
    }
}

#pragma mark target/actions
- (IBAction)endOfStoryButtonPressed:(id)sender
{
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void) refreshStoryList:(id)sender
{
    [self.refreshControl beginRefreshing];
    [self.activityView startAnimating];
    self.tableView.tableFooterView = self.activityView;
    [BanyanConnection loadDataSource:sender];
}

// Called by both data source updated notification and by clicking on the filter segmented control
- (IBAction)filterStories:(id)sender
{
    [self.refreshControl endRefreshing];
    [self.activityView stopAnimating];
    
    // Update the footer view
    if ([[BanyanConnection storiesPaginator] isLoaded] && ![[BanyanConnection storiesPaginator] hasNextPage]) {
        self.endOfStoryButton.titleLabel.numberOfLines = 1;
        [self.endOfStoryButton setTitle:@"That's all folks!" forState:UIControlStateNormal];
        self.endOfStoryButton.titleLabel.font = [UIFont fontWithName:@"ThatsFontFolksItalic" size:40];
        self.tableView.tableFooterView = self.endOfStoryButton;
    }
    if ([[BanyanConnection storiesPaginator].objectRequestOperation isFinished] && [BanyanConnection storiesPaginator].objectRequestOperation.HTTPRequestOperation.error) {
        self.endOfStoryButton.titleLabel.numberOfLines = 2;
        [self.endOfStoryButton setTitle:@"Error in loading new stories.\rPlease try again." forState:UIControlStateNormal];
        self.endOfStoryButton.titleLabel.font = [UIFont fontWithName:@"Roboto" size:16];;
        self.tableView.tableFooterView = self.endOfStoryButton;
    }
    if (!self.fetchedResultsController.delegate) {
        [self performFetch];
    }
}

#pragma mark Story Manipulations
-(void) readStoryForIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    SingleStoryCell *singleStoryCell = (SingleStoryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    Piece *pieceToShow = [singleStoryCell currentlyVisiblePiece];
    
    if (!pieceToShow) {
        [self.tableView reloadData];
        return;
    }
    [self storyReaderWithStory:story piece:pieceToShow];
}

- (void)storyReaderWithStory:(Story *)story piece:(Piece *)piece
{
    StoryReaderController *storyReaderController = [[StoryReaderController alloc] initWithPiece:piece];
    storyReaderController.story = story;
    storyReaderController.delegate = self;
    storyReaderController.hidesBottomBarWhenPushed = YES;
    storyReaderController.transitioningDelegate = self;
    
    [self presentViewController:storyReaderController animated:YES completion:nil];
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

-(IBAction) addStoryOrLoginButtonPressed:(UIButton *)sender
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![BanyanAppDelegate loggedIn]) {
        [delegate login];
    } else {
        // Show the story picker view controller.
        StoryPickerViewController *vc = [[StoryPickerViewController alloc] init];
        vc.delegate = self;
        UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nvc animated:YES completion:nil];
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

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

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactionController.interactionInProgress ? self.interactionController : nil;
}


# pragma mark StoryPickerViewControllerDelegate
- (void) storyPickerViewControllerDidPickStory:(Story *)story
{
    [self addPieceToStory:story];
}


#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"contentSize.height(%f) - contentOffset.y(%f)", scrollView.contentSize.height, scrollView.contentOffset.y);
    if (scrollView.contentSize.height - scrollView.contentOffset.y < 1130 /* ~ 2*CGRectGetHeight(self.view.bounds */) {
        if ([[BanyanConnection storiesPaginator] objectRequestOperation].isFinished && [[BanyanConnection storiesPaginator] isLoaded] && [[BanyanConnection storiesPaginator] hasNextPage]) {
            [[BanyanConnection storiesPaginator] loadNextPage];
            BNLogInfo(@"StoryListTableViewController loadDataSource BEGIN for page %d", [BanyanConnection storiesPaginator].currentPage);
            [self.activityView startAnimating];
            self.tableView.tableFooterView = self.activityView;
        }
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

@implementation StoryListTableViewController (StoryReaderControllerDelegate)

- (Story *) storyReaderControllerGetNextStory:(StoryReaderController *)storyReaderController
{
    Story *currentStory = storyReaderController.story;
    NSIndexPath *currentIndexPath = [self.fetchedResultsController indexPathForObject:currentStory];
    if (currentIndexPath) {
        NSUInteger i = 1;
        Story *nextStory = nil;
        do {
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row+1 inSection:currentIndexPath.section];
            @try {
                nextStory = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
                if (nextStory.pieces.count)
                    return nextStory;
                else
                    i++;
            }
            @catch (NSException *exception) {
                [BNMisc sendGoogleAnalyticsException:exception inAction:@"Getting next story" isFatal:NO];
                return nil;
            }
        } while (nextStory); // Get the next story that has some piece to read
    } else {
        return nil;
    }
}

- (void)storyReaderControllerReadNextStory:(Story *)nextStory
{
    if (nextStory && nextStory.pieces.count) {
        Piece *piece = [nextStory.pieces objectAtIndex:0];
        if (piece) {
            [self storyReaderWithStory:nextStory piece:piece];
        }
    }
}

@end

@implementation StoryListTableViewController (MYIntroductionDelegate)

-(void)introduction:(MYBlurIntroductionView *)introductionView didFinishWithType:(MYFinishType)finishType
{
    [introductionView removeFromSuperview];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    // We only show this if the use has just started the app
    if (![BanyanAppDelegate loggedIn]) {
        CMPopTipView *popTipView = [[CMPopTipView alloc] initWithTitle:@"Sign in" message:@"Sign in (using Facebook) to see, create and contribute to more stories"];
        SET_CMPOPTIPVIEW_APPEARANCES(popTipView);
        [popTipView presentPointingAtBarButtonItem:self.navigationItem.rightBarButtonItem animated:NO];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *firstTimeDict = [[defaults dictionaryForKey:BNUserDefaultsFirstTimeActionsDict] mutableCopy];
    [firstTimeDict setObject:[NSNumber numberWithBool:YES] forKey:BNUserDefaultsFirstTimeAppOpen];
    [firstTimeDict setObject:[NSNumber numberWithBool:YES] forKey:BNUserDefaultsFirstTimeStoryListVCWoSignin];
    [defaults setObject:firstTimeDict forKey:BNUserDefaultsFirstTimeActionsDict];
    [defaults synchronize];
    
}

-(void)introduction:(MYBlurIntroductionView *)introductionView didChangeToPanel:(MYIntroductionPanel *)panel withIndex:(NSInteger)panelIndex
{
    UIImage *image = nil;
    // You can edit introduction view properties right from the delegate method!
    if (panelIndex == 0) {
        image = [UIImage imageNamed:@"IntroBkg2"];
        [introductionView setBackgroundColor:[BANYAN_WHITE_COLOR colorWithAlphaComponent:0.5]];
    } else if (panelIndex == 1) {
        image = [UIImage imageNamed:@"IntroBkg3"];
        [introductionView setBackgroundColor:[BANYAN_WHITE_COLOR colorWithAlphaComponent:0.4]];
    }
    panel.PanelTitleLabel.textColor = BANYAN_BLACK_COLOR;
    panel.PanelDescriptionLabel.textColor = BANYAN_BLACK_COLOR;
    panel.PanelTitleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:24];
    panel.PanelDescriptionLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:14];

    introductionView.BackgroundImageView.image = image;
}
@end