//
//  StoryOverviewHeaderView.m
//  Banyan
//
//  Created by Devang Mundhra on 12/13/13.
//
//

#import "StoryOverviewHeaderView.h"
#import "Story+Permissions.h"
#import "BNMisc.h"
#import "BNLabel.h"
#import "MZFormSheetController.h"
#import "BanyanAppDelegate.h"
#import "ContributorsTableViewController.h"

@interface StoryOverviewHeaderView ()
@property (strong, nonatomic) IBOutlet BNLabel *storyDateLabel;
@property (strong, nonatomic) UIView *lineView1;
@property (strong, nonatomic) IBOutlet UIButton *storyContributorsButton;
@property (strong, nonatomic) UIView *lineView2;
@property (strong, nonatomic) NSArray *arrayOfContributors;

@end

@implementation StoryOverviewHeaderView
@synthesize storyDateLabel = _storyDateLabel;
@synthesize storyContributorsButton = _storyContributorsButton;
@synthesize story = _story;
@synthesize lineView1, lineView2;
@synthesize arrayOfContributors = _arrayOfContributors;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = BANYAN_WHITE_COLOR;
        self.clipsToBounds = YES;
        
#define VIEW_INSETS 5
        // Story Permissions
        frame = self.bounds;
        frame.size.height = STORYOVERVIEW_HEADERVIEW_HEIGHT/2 - 2;
        self.storyDateLabel = [[BNLabel alloc] initWithFrame:frame];
        self.storyDateLabel.textEdgeInsets = UIEdgeInsetsMake(VIEW_INSETS, VIEW_INSETS, VIEW_INSETS, VIEW_INSETS);
        self.storyDateLabel.font = [UIFont fontWithName:@"Roboto" size:14];
        self.storyDateLabel.textColor = BANYAN_BLACK_COLOR;
        self.storyDateLabel.textAlignment = NSTextAlignmentCenter;
        self.storyDateLabel.minimumScaleFactor = 0.5;
        [self addSubview:self.storyDateLabel];
        
        frame.origin.y = CGRectGetMaxY(self.storyDateLabel.frame);
        frame.size.height = 1;
        frame.origin.x = 2*VIEW_INSETS;
        frame.size.width -= 4*VIEW_INSETS;
        lineView1 = [[UIView alloc] initWithFrame:frame];
        lineView1.backgroundColor = BANYAN_LIGHTGRAY_COLOR;
        [self addSubview:lineView1];
        
        frame = self.bounds;
        frame.origin.y = CGRectGetMaxY(lineView1.frame);
        frame.size.height = STORYOVERVIEW_HEADERVIEW_HEIGHT/2;
        self.storyContributorsButton = [[UIButton alloc] initWithFrame:frame];
        [self.storyContributorsButton setTitleColor:BANYAN_BLACK_COLOR forState:UIControlStateNormal];
        [self.storyContributorsButton setTitleEdgeInsets:UIEdgeInsetsMake(VIEW_INSETS, VIEW_INSETS, VIEW_INSETS, VIEW_INSETS)];
        self.storyContributorsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.storyContributorsButton.titleLabel.numberOfLines = 2;
        [self.storyContributorsButton addTarget:self action:@selector(contributorsDetailsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.storyContributorsButton];
        
        frame.origin.y = CGRectGetMaxY(self.storyContributorsButton.frame);
        frame.size.height = 1;
        frame.origin.x = 2*VIEW_INSETS;
        frame.size.width -= 4*VIEW_INSETS;
        lineView2 = [[UIView alloc] initWithFrame:frame];
        lineView2.backgroundColor = BANYAN_LIGHTGRAY_COLOR;
        [self addSubview:lineView2];
#undef VIEW_INSETS
    }
    return self;
}

- (void) setStory:(Story *)story
{
    _story = story;
    self.storyDateLabel.text = [NSString stringWithFormat:@"Started on %@", [[BNMisc longDateFormatter] stringFromDate:story.createdAt]];
    [self updateStoryContributorsSummary];
}

- (void) updateStoryContributorsSummary
{
    self.arrayOfContributors = [self.story sortedArrayOfPieceContributorsWithCount];
    
    NSAttributedString *contrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d contributors have contributed to the story\r", self.arrayOfContributors.count]
                                                                      attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14]}];
    NSAttributedString *tapStr = [[NSAttributedString alloc] initWithString:@"Tap for more details about contributors"
                                                                 attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                   NSForegroundColorAttributeName: BANYAN_GRAY_COLOR}];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithAttributedString:contrString];
    [attrString appendAttributedString:tapStr];
    [self.storyContributorsButton setAttributedTitle:attrString forState:UIControlStateNormal];
}

- (IBAction)contributorsDetailsButtonPressed:(id)sender
{
    UIViewController *vc = [[ContributorsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:vc];
    formSheet.transitionStyle = MZFormSheetTransitionStyleSlideFromTop;
    formSheet.shadowRadius = 2.0;
    formSheet.shadowOpacity = 0.3;
    formSheet.shouldDismissOnBackgroundViewTap = YES;
    __weak StoryOverviewHeaderView *wself = self;
    formSheet.willPresentCompletionHandler = ^(UIViewController *presentedFSViewController) {
        // Passing data
        ContributorsTableViewController *conVC = (ContributorsTableViewController *)presentedFSViewController;
        conVC.dataSource = wself.arrayOfContributors;
        [conVC.tableView reloadData];
    };
    
    [APP_DELEGATE.topMostController mz_presentFormSheetController:formSheet animated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        
    }];
}

@end
