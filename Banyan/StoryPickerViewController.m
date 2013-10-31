//
//  StoryPickerViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 10/28/13.
//
//

#import "StoryPickerViewController.h"
#import "ModifyStoryViewController.h"

static NSString *CellIdentifier = @"StoryPickerCell";

@interface StoryPickerViewController (ModifyStoryViewControllerDelegate)<ModifyStoryViewControllerDelegate>

@end

@interface StoryPickerViewController (UICollectionViewDelegateFlowLayout)<UICollectionViewDelegateFlowLayout>

@end

@interface StoryPickerViewController ()
@property (strong, nonatomic) NSArray *contributableStories;


@end

@implementation StoryPickerViewController
@synthesize contributableStories = _contributableStories;
@synthesize delegate = _delegate;

- (id)init
{
    UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:aFlowLayout];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.collectionView registerClass:[StoryPickerCell class] forCellWithReuseIdentifier:CellIdentifier];
    
    self.title = @"Choose a story";
    self.collectionView.backgroundColor = BANYAN_LIGHTGRAY_COLOR;

    [self setupNavigationBar];
    
    NSMutableArray *storiesArray = [NSMutableArray arrayWithArray:[Story getStoriesUserCanContributeTo]];
    [storiesArray insertObject:[NSNull null] atIndex:0]; // To add new story
//    [storiesArray insertObject:[NSNull null] atIndex:[storiesArray count]];
    
    self.contributableStories = [storiesArray copy];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL) isAddStoryIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0 && indexPath.item == 0);
}

- (BOOL) isMoreStoriesIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0 && indexPath.item == self.contributableStories.count-1);
}

- (void)setupNavigationBar
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(cancelButtonPressed:)];
}

#pragma mark
#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.contributableStories count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    StoryPickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if ([self isAddStoryIndexPath:indexPath]) {
        [cell displayAsAddStoryButton];
    } else {
        Story *story = [self.contributableStories objectAtIndex:indexPath.item];
        [cell setStory:story];
    }
    return cell;
}

#pragma mark
#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    if ([self isAddStoryIndexPath:indexPath]) {
        [self createNewStory:nil];
    } else {
        Story *story = [self.contributableStories objectAtIndex:indexPath.item];
        
        [self dismissStoryPickerViewControllerAnimated:YES completionBlock:^{
            [self.delegate storyPickerViewControllerDidPickStory:story];
        }];
    }
}

#pragma mark target actions
- (void) createNewStory:(id)sender
{
    Story *story = [Story newDraftStory];
    ModifyStoryViewController *newStoryViewController = [[ModifyStoryViewController alloc] initWithStory:story];
    newStoryViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newStoryViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void) getMoreStories:(id)sender
{
    
}

- (void) cancelButtonPressed:(id)sender
{
    [self dismissStoryPickerViewControllerAnimated:YES completionBlock:nil];
}

- (void) dismissStoryPickerViewControllerAnimated:(BOOL)animated completionBlock:(void (^)(void))completionBlock
{
    [self dismissViewControllerAnimated:animated completion:completionBlock];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation StoryPickerViewController (UICollectionViewDelegateFlowLayout)

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isAddStoryIndexPath:indexPath])
        return CGSizeMake(CGRectGetWidth(collectionView.frame) - 10, 44);
    else
        return CGSizeMake(CGRectGetWidth(collectionView.frame)/2-10, 80);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

@end

@implementation StoryPickerViewController (ModifyStoryViewControllerDelegate)

- (void) modifyStoryViewControllerDidDismiss:(ModifyStoryViewController *)viewController
{
}

- (void) modifyStoryViewControllerDidSelectStory:(Story *)story
{
    if (HAVE_ASSERTS) {
        assert(story);
    }
    [self dismissStoryPickerViewControllerAnimated:YES completionBlock:^{
        [self.delegate storyPickerViewControllerDidPickStory:story];
    }];
}

@end