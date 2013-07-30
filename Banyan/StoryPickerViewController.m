//
//  StoryPickerViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 7/28/13.
//
//

#import "StoryPickerViewController.h"
#import "User.h"

@interface StoryPickerViewController ()
@property (strong, nonatomic) NSArray *contributableStories;

@end

@implementation StoryPickerViewController

@synthesize contributableStories = _contributableStories;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Choose a story";
    
    [self setupNavigationBar];
    
    [self addNewStoryButton];
    //    [self addGetMoreStoriesButton];
    
    self.contributableStories = [Story getStoriesUserCanContributeTo];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)setupNavigationBar
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backArrow"]
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(cancelButtonPressed:)];
}

- (void) addNewStoryButton
{
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 40);
    [actionButton.titleLabel setFont:[UIFont fontWithName:@"Roboto" size:16]];
    [actionButton setTitleColor:BANYAN_BLACK_COLOR forState:UIControlStateNormal];
    actionButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    actionButton.userInteractionEnabled = YES;
    [actionButton setBackgroundColor:BANYAN_CREAM_COLOR];
    
    [actionButton setTitle:@"Create a new story" forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(createNewStory:) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableHeaderView = actionButton;
}

- (void) addGetMoreStoriesButton
{
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 40);
    [actionButton.titleLabel setFont:[UIFont fontWithName:@"Roboto" size:16]];
    [actionButton setTitleColor:BANYAN_BLACK_COLOR forState:UIControlStateNormal];
    actionButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    actionButton.userInteractionEnabled = YES;
    [actionButton setBackgroundColor:BANYAN_CREAM_COLOR];
    
    [actionButton setTitle:@"Get more stoies" forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(getMoreStories:) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableFooterView = actionButton;
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
    return [self.contributableStories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StoryPickerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    Story *story = [self.contributableStories objectAtIndex:indexPath.row];
    cell.textLabel.text = story.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Started by: %@", story.author.name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Story *story = [self.contributableStories objectAtIndex:indexPath.row];

    [self dismissStoryPickerViewControllerWithCompletionBlock:^{
        [self.delegate storyPickerViewControllerDidPickStory:story];
    }];
}

#pragma mark target actions
- (void) createNewStory:(id)sender
{
    Story *story = [Story newDraftStory];
    ModifyStoryViewController *newStoryViewController = [[ModifyStoryViewController alloc] initWithStory:story];
    newStoryViewController.delegate = self;
    [self presentViewController:newStoryViewController animated:YES completion:nil];
}

- (void) getMoreStories:(id)sender
{
    
}

- (void) cancelButtonPressed:(id)sender
{
    [self dismissStoryPickerViewControllerWithCompletionBlock:nil];
}

#pragma mark ModifyStoryViewControllerDelegate
- (void) modifyStoryViewControllerDidDismiss:(ModifyStoryViewController *)viewController
{
    [self dismissStoryPickerViewControllerWithCompletionBlock:nil];
}

- (void) modifyStoryViewControllerDidSelectStory:(Story *)story
{
    if (HAVE_ASSERTS) {
        assert(story);
    }
    [self dismissStoryPickerViewControllerWithCompletionBlock:^{
        [self.delegate storyPickerViewControllerDidPickStory:story];
    }];
}

- (void) dismissStoryPickerViewControllerWithCompletionBlock:(void (^)(void))completionBlock
{
    [self dismissViewControllerAnimated:YES completion:completionBlock];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end