//
//  MasterTabBarController.m
//  Banyan
//
//  Created by Devang Mundhra on 7/28/13.
//
//

#import "MasterTabBarController.h"
#import "StoryListTableViewController.h"
#import "SettingsTableViewController.h"
#import "BanyanAppDelegate.h"

@interface MasterTabBarController ()

@end

@implementation MasterTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)setup
{
    StoryListTableViewController *storyListVC = [[StoryListTableViewController alloc] init];
    storyListVC.title = @"Stories";
    
    UITabBarItem *storyListTabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"homeTabSymbol"] tag:0];
    
    UITableViewController *searchVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    UITabBarItem *searchTabBarItem = [[UITabBarItem alloc] initWithTitle:@"Search" image:[UIImage imageNamed:@"searchTabSymbol"] tag:0];
    
    UIImage *buttonImage = [UIImage imageNamed:@"addWithGreen"];
    [self addCenterButtonWithImage:buttonImage andTarget:self withAction:@selector(addTabButtonPressed:)];
    
    SettingsTableViewController *settingsVC = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UITabBarItem *settingsTabBar = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"userProfileTabSymbol"] tag:0];
    
    UINavigationController *storyListNavigationController = [[UINavigationController alloc] initWithRootViewController:storyListVC];
    UINavigationController *searchNavigationController = [[UINavigationController alloc] initWithRootViewController:searchVC];
    UINavigationController *profileNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    
    [storyListNavigationController setTabBarItem:storyListTabBarItem];
    [searchNavigationController setTabBarItem:searchTabBarItem];
    [profileNavigationController setTabBarItem:settingsTabBar];
    
    [self setViewControllers:@[storyListNavigationController, /*searchNavigationController,*/ profileNavigationController] animated:YES];
}

-(IBAction) addTabButtonPressed:(UIButton *)sender
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
            StoryListTableViewController *listVc = [[self.tabBarController viewControllers] objectAtIndex:0];
            [listVc addPieceToStory:story];        }
    }
}

# pragma mark StoryPickerViewControllerDelegate
- (void) storyPickerViewControllerDidPickStory:(Story *)story
{
    StoryListTableViewController *listVc = [[self viewControllers] objectAtIndex:0];
    [listVc addPieceToStory:story];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
