//
//  StoryOverviewController.m
//  Banyan
//
//  Created by Devang Mundhra on 12/12/13.
//
//

#import "StoryOverviewController.h"
#import "StoryOverviewPieceCell.h"
#import "ModifyStoryViewController.h"
#import "Story+Permissions.h"
#import "BanyanAppDelegate.h"
#import "User.h"
#import "Story+Delete.h"
#import "StoryOverviewHeaderView.h"
#import "Story+Share.h"
#import "Story+Stats.h"
#import "MBProgressHUD.h"
#import "Appirater.h"

static NSString *CellIdentifier = @"StoryOverview_PieceCell";
static NSString *HeaderIdentifier = @"StoryOverview_Header";

static NSString *const deleteStoryString = @"Delete story";
static NSString *const flagStoryString = @"Flag story";
static NSString *const editStoryString = @"Edit story";
static NSString *const shareString = @"Share";
static NSString *const cancelString = @"Cancel";
static NSString *const followStoryString = @"Follow story";
static NSString *const unfollowStoryString = @"Unfollow story";

@interface StoryOverviewController (UIAlertViewDelegateAndActionSheetDelegate) <UIAlertViewDelegate, UIActionSheetDelegate>
@end
@interface StoryOverviewController (UICollectionViewDataSource) <UICollectionViewDataSource>
@end
@interface StoryOverviewController (UICollectionViewDelegateFlowLayout) <UICollectionViewDelegateFlowLayout>
@end

@interface StoryOverviewController ()

@property (strong, nonatomic) Story *story;
@property (strong, nonatomic) IBOutlet UICollectionView *piecesCollectionView;

@end

@implementation StoryOverviewController
@synthesize story = _story;
@synthesize piecesCollectionView = _piecesCollectionView;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithStory:(Story *)story
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.story = story;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIImage *backArrowImage = [UIImage imageNamed:@"Previous"];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage:backArrowImage style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    [self.navigationItem setLeftBarButtonItem:leftButton];
    
    UIImage *settingsImage = [UIImage imageNamed:@"Cog"];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStyleBordered target:self action:@selector(settingsPopup:)];
    [self.navigationItem setRightBarButtonItem:rightButton];
    
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    [self setStoryTitleInNavigationItem];
    
    // Piece collection view
    CGRect frame = self.view.bounds;
#define COLL_VIEW_INSET 4
    UICollectionViewFlowLayout *collViewLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat pcSz = ceilf(CGRectGetWidth(frame)/3) - 3*COLL_VIEW_INSET;
    collViewLayout.itemSize = CGSizeMake(pcSz, pcSz);
    collViewLayout.sectionInset = UIEdgeInsetsMake(COLL_VIEW_INSET, COLL_VIEW_INSET, COLL_VIEW_INSET, COLL_VIEW_INSET);
    collViewLayout.headerReferenceSize = CGSizeMake(frame.size.width, STORYOVERVIEW_HEADERVIEW_HEIGHT);
#undef COLL_VIEW_INSET
    frame.size.height -= STORYOVERVIEW_HEADERVIEW_HEIGHT;
    self.piecesCollectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:collViewLayout];
    self.piecesCollectionView.backgroundColor = BANYAN_WHITE_COLOR;
    self.piecesCollectionView.dataSource = self;
    self.piecesCollectionView.delegate = self;
    self.piecesCollectionView.showsVerticalScrollIndicator = NO;
    [self.piecesCollectionView registerClass:[StoryOverviewPieceCell class] forCellWithReuseIdentifier:CellIdentifier];
    [self.piecesCollectionView registerClass:[StoryOverviewHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HeaderIdentifier];
    
    [self.view addSubview:self.piecesCollectionView];
}

- (void) setStoryTitleInNavigationItem
{
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.navigationController.navigationBar.frame) - 80,
                                                                    CGRectGetHeight(self.navigationController.navigationBar.frame))];
    titleLabel.numberOfLines = 2;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    NSMutableAttributedString *titleString = nil;
    
    if (self.story.title.length <= 20) {
        titleString = [[NSMutableAttributedString alloc] initWithString:self.story.title
                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                          NSForegroundColorAttributeName: BANYAN_BLACK_COLOR}];
    } else {
        titleString = [[NSMutableAttributedString alloc] initWithString:self.story.title
                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:12],
                                                                          NSForegroundColorAttributeName: BANYAN_BLACK_COLOR}];
    }
    
    NSAttributedString *appendString = [[NSAttributedString alloc] initWithString:@"\roverview"
                                                                       attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                    NSForegroundColorAttributeName: BANYAN_GRAY_COLOR}];
    
    [titleString appendAttributedString:appendString];
    titleLabel.attributedText = titleString;
    
    // Story title label
    self.navigationItem.titleView = titleLabel;
}

#pragma mark notifications
- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (!self.story) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
    
    if ([insertedObjects containsObject:self.story] || [updatedObjects containsObject:self.story]) {
        [self refreshUI];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Story Overview Screen"];
}

- (void) refreshUI
{
    [self setStoryTitleInNavigationItem];
    [self.piecesCollectionView reloadData];
}

# pragma mark target/actions
- (void)settingsPopup:(id)sender
{
    
    UIActionSheet *actionSheet = nil;
    if ([BanyanAppDelegate loggedIn]) {
        if (self.story.canContribute) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:cancelString
                                        destructiveButtonTitle:self.story.author.userId == [BNSharedUser currentUser].userId ? deleteStoryString : flagStoryString
                                             otherButtonTitles:editStoryString, self.story.followActivityResourceUri.length ? unfollowStoryString : followStoryString, shareString, nil];
        } else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:cancelString
                                        destructiveButtonTitle:self.story.author.userId == [BNSharedUser currentUser].userId ? deleteStoryString : flagStoryString
                                             otherButtonTitles:self.story.followActivityResourceUri.length ? unfollowStoryString : followStoryString, shareString, nil];
        }
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelString
                                    destructiveButtonTitle:flagStoryString
                                         otherButtonTitles:shareString, nil];
    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation StoryOverviewController (UICollectionViewDataSource)

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    StoryOverviewPieceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    Piece *piece = [self.story.pieces objectAtIndex:indexPath.item];
    cell.piece = piece;
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.story.pieces.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    StoryOverviewHeaderView *headerView = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                        withReuseIdentifier:HeaderIdentifier forIndexPath:indexPath];
        headerView.story = self.story;
    }
    
    return headerView;
}

@end

@implementation StoryOverviewController (UICollectionViewDelegateFlowLayout)

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    Piece *piece = [self.story.pieces objectAtIndex:indexPath.item];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate storyOverviewControllerSelectedPiece:piece];
    }];
    [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction"
                                          action:@"story overview"
                                           label:@"selected a piece"
                                           value:[NSNumber numberWithInt:indexPath.item]];
}

@end

@implementation StoryOverviewController (UIAlertViewDelegateAndActionSheetDelegate)

#pragma mark Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // DO NOTHING ON CANCEL
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:deleteStoryString]) {
        // Delete story
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:deleteStoryString
                                                            message:@"Do you want to delete this story?"
                                                           delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        
        [alertView show];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:flagStoryString]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:flagStoryString
                                                            message:@"Do you want to report this story as inappropriate?\rYou can optionally specify a brief message for the reviewers."
                                                           delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        [alertView show];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:editStoryString]) {
        ModifyStoryViewController *newStoryViewController = [[ModifyStoryViewController alloc] initWithStory:self.story];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newStoryViewController];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:followStoryString]) {
        __weak typeof(self) wself = self;
        // Follow story
        [self.story followWithCompletionBlock:^(bool succeeded, NSError *error) {
            if (wself) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:wself.view animated:YES];
                    hud.labelFont = [UIFont fontWithName:@"Roboto" size:12];
                    hud.mode = MBProgressHUDModeText;
                    if (succeeded)
                        hud.labelText = @"Follow story - success";
                    else
                        hud.labelText = @"Follow story - error";
                    [hud hide:YES afterDelay:2];
                });
            }
        }];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:unfollowStoryString]) {
        // Unfollow story
        __weak typeof(self) wself = self;
        [self.story unfollowWithCompletionBlock:^(bool succeeded, NSError *error) {
            if (wself) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.labelFont = [UIFont fontWithName:@"Roboto" size:12];
                    hud.mode = MBProgressHUDModeText;
                    if (succeeded)
                        hud.labelText = @"Unfollow story - success";
                    else
                        hud.labelText = @"Unfollow story - error";
                    [hud hide:YES afterDelay:2];
                });
            }
        }];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:shareString]) {
        // Share
        [self.story shareOnFacebook];
    }
    [Appirater userDidSignificantEvent:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:deleteStoryString] && buttonIndex==1) {
        [Story deleteStory:self.story completion:^{
            [self dismissViewControllerAnimated:YES completion:^{
                [self.delegate storyOverviewControllerDeletedStory];
            }];
        }];
    } else if ([alertView.title isEqualToString:flagStoryString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        NSString *message = [alertView textFieldAtIndex:0].text;
        [self.story flaggedWithMessage:message];
    }
}

@end