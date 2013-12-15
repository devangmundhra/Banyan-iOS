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
#import "NSObject+BlockObservation.h"
#import "StoryOverviewHeaderView.h"

static NSString *CellIdentifier = @"StoryOverview_PieceCell";
static NSString *HeaderIdentifier = @"StoryOverview_Header";

@interface StoryOverviewController (UIAlertViewDelegateAndActionSheetDelegate) <UIAlertViewDelegate, UIActionSheetDelegate>
@end
@interface StoryOverviewController (UICollectionViewDataSource) <UICollectionViewDataSource>
@end
@interface StoryOverviewController (UICollectionViewDelegateFlowLayout) <UICollectionViewDelegateFlowLayout>
@end

@interface StoryOverviewController ()

@property (strong, nonatomic) Story *story;
@property (strong, nonatomic) IBOutlet UICollectionView *piecesCollectionView;

@property (strong, nonatomic) AMBlockToken *storyObserverToken1;
@property (strong, nonatomic) AMBlockToken *storyObserverToken2;
@property (strong, nonatomic) AMBlockToken *storyObserverToken3;
@property (strong, nonatomic) AMBlockToken *storyObserverToken4;

@end

@implementation StoryOverviewController
@synthesize story = _story;
@synthesize piecesCollectionView = _piecesCollectionView;
@synthesize storyObserverToken1, storyObserverToken2, storyObserverToken3, storyObserverToken4;
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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIImage *backArrowImage = [UIImage imageNamed:@"backArrow"];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage:backArrowImage style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    [self.navigationItem setLeftBarButtonItem:leftButton];
    
    if (self.story.canContribute) {
        UIImage *settingsImage = [UIImage imageNamed:@"settingsButton"];
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStyleBordered target:self action:@selector(settingsPopup:)];
        [self.navigationItem setRightBarButtonItem:rightButton];
    }
    
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    // Story title label
    self.navigationItem.title = self.story.title;
    
    // Piece collection view
    CGRect frame = self.view.bounds;
#define COLL_VIEW_INSET 5
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
    [self addStoryObserver];
}

#pragma mark notifications
- (void)addStoryObserver
{
    __weak StoryOverviewController *wself = self;
    storyObserverToken1 = [self.story addObserverForKeyPath:@"title" task:^(id obj, NSDictionary *change) {
        [wself refreshUI];
    }];
    storyObserverToken2 = [self.story addObserverForKeyPath:@"writeAccess" task:^(id obj, NSDictionary *change) {
        [wself refreshUI];
    }];
    storyObserverToken3 = [self.story addObserverForKeyPath:@"readAccess" task:^(id obj, NSDictionary *change) {
        [wself refreshUI];
    }];
    storyObserverToken3 = [self.story addObserverForKeyPath:@"pieces" task:^(id obj, NSDictionary *change) {
        [wself refreshUI];
    }];
}

- (void)removeStoryObserver
{
    if (storyObserverToken1) {
        [self.story removeObserverWithBlockToken:storyObserverToken1];
        storyObserverToken1 = nil;
    }
    if (storyObserverToken2) {
        [self.story removeObserverWithBlockToken:storyObserverToken2];
        storyObserverToken2 = nil;
    }
    if (storyObserverToken3) {
        [self.story removeObserverWithBlockToken:storyObserverToken3];
        storyObserverToken3 = nil;
    }
    if (storyObserverToken4) {
        [self.story removeObserverWithBlockToken:storyObserverToken4];
        storyObserverToken4 = nil;
    }
}

- (void) refreshUI
{
    self.navigationItem.title = self.story.title;
    [self.piecesCollectionView reloadData];
}

# pragma mark target/actions
- (void)settingsPopup:(id)sender
{
    UIActionSheet *actionSheet = nil;
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                              delegate:self
                                     cancelButtonTitle:@"Cancel"
                                destructiveButtonTitle:self.story.author.userId == [BNSharedUser currentUser].userId ? @"Delete story" : nil
                                     otherButtonTitles:@"Edit story", @"Share via Facebook", nil];
    
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
    [self removeStoryObserver];
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
    else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // Delete story
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Story"
                                                            message:@"Do you want to delete this story?"
                                                           delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        
        [alertView show];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Edit story"]) {
        ModifyStoryViewController *newStoryViewController = [[ModifyStoryViewController alloc] initWithStory:self.story];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newStoryViewController];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share via Facebook"]) {
        // Share
        [self.story shareOnFacebook];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete Story"] && buttonIndex==1) {
        [Story deleteStory:self.story completion:^{
            [self dismissViewControllerAnimated:YES completion:^{
                [self.delegate storyOverviewControllerDeletedStory];
            }];
        }];
    }
}

@end