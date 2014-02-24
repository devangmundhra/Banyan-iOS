//
//  NextStoryViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 11/5/13.
//
//

#import "NextStoryViewController.h"
#import "Story+Permissions.h"
#import "Media.h"
#import "UIImage+ImageEffects.h"

@interface NextStoryViewController (UIGestureRecognizerDelegate) <UIGestureRecognizerDelegate>

@end

@interface NextStoryViewController ()

@end

@implementation NextStoryViewController
@synthesize delegate = _delegate;
@synthesize nextStory = _nextStory;
@synthesize currentStory = _currentStory;

- (id)init
{
    self = [super init];
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
#define CORNER_RADIUS 8.0f
#define TEXT_INSETS 6
#define VIEW_INSETS 8
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    
    // Set the Navigation Item Views
    // Title of Story
    self.navigationItem.title = self.currentStory.title;
    
    // Back button
    UIImage *prevImage = [UIImage imageNamed:@"Previous"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 80, prevImage.size.height);
    [backButton setImage:prevImage forState:UIControlStateNormal];
    [backButton setTitle:@"Stories" forState:UIControlStateNormal];
    [backButton setTitleColor:BANYAN_GREEN_COLOR forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont fontWithName:@"Roboto" size:16]];
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10.0f, 0, -10.0f)];
    [backButton addTarget:self action:@selector(goToStoryList:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backBarButton;
    
    // Add piece button
    if (self.currentStory.canContribute) {
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPieceToStory:)];
        self.navigationItem.rightBarButtonItem = rightButton;
    }
    
    // Show the content of the view
    UILabel *theEndLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    theEndLabel.text = @"The End";
    theEndLabel.font = [UIFont fontWithName:@"ThatsFontFolksItalic" size:32];
    theEndLabel.textAlignment = NSTextAlignmentCenter;
    CGRect frame = self.view.bounds;
    frame.size.width -= 2*VIEW_INSETS;
    frame.size.height = 100;
    frame.origin.x = VIEW_INSETS;
    frame.origin.y = CGRectGetMaxY(self.navigationController.navigationBar.frame) + 2*VIEW_INSETS;
    theEndLabel.frame = frame;
    CGPoint center = theEndLabel.center;
    [theEndLabel sizeToFit];
    theEndLabel.center = center;
    [self.view addSubview:theEndLabel];
    
    if (self.nextStory) {
        UILabel *nextStoryLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        nextStoryLabel.text = @"Next story";
        nextStoryLabel.textAlignment = NSTextAlignmentCenter;
        nextStoryLabel.font = [UIFont fontWithName:@"Roboto" size:16];
        frame.origin.y = CGRectGetMaxY(theEndLabel.frame) + 2*VIEW_INSETS;
        frame.size.height = 100;
        nextStoryLabel.frame = frame;
        center = nextStoryLabel.center;
        [nextStoryLabel sizeToFit];
        nextStoryLabel.center = center;
        [self.view addSubview:nextStoryLabel];
        
        // Next Story Button
        UIButton *nextStoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nextStoryButton addTarget:self action:@selector(goToNextStory:) forControlEvents:UIControlEventTouchUpInside];
        nextStoryButton.backgroundColor = BANYAN_WHITE_COLOR;
        
        nextStoryButton.titleLabel.numberOfLines = 0;
        nextStoryButton.contentEdgeInsets = UIEdgeInsetsMake(TEXT_INSETS, TEXT_INSETS, TEXT_INSETS, TEXT_INSETS);
        nextStoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        nextStoryButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.alignment = NSTextAlignmentCenter;
        NSMutableAttributedString *nextStoryString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\r", self.nextStory.title]
                                                                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:14],
                                                                                                         NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,}];
        NSAttributedString *storyContributorString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"by %@", [self.nextStory shortStringOfContributors]]
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:12],
                                                                                            NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR,}];

        [nextStoryString appendAttributedString:storyContributorString];
        [nextStoryString addAttribute:NSParagraphStyleAttributeName value:paraStyle
                                range:NSMakeRange(0, [nextStoryString string].length)];
        [nextStoryButton setAttributedTitle:nextStoryString
                                   forState:UIControlStateNormal];
        
        frame.origin.y = CGRectGetMaxY(nextStoryLabel.frame) + VIEW_INSETS;
        frame.size.height = CGRectGetHeight(self.view.bounds)-CGRectGetMaxY(frame);
        CGSize buttonSize = [nextStoryString.string boundingRectWithSize:frame.size
                                                                 options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:14],
                                                                           NSParagraphStyleAttributeName: paraStyle}
                                                                 context:nil].size;
        frame.size.height = buttonSize.height;
        nextStoryButton.frame = frame;
        nextStoryButton.layer.cornerRadius = CORNER_RADIUS;
        nextStoryButton.layer.shadowOffset = CGSizeMake(5, 2);
        nextStoryButton.layer.shadowRadius = 3;
        nextStoryButton.layer.shadowOpacity = 0.5;
        nextStoryButton.layer.shadowPath = [UIBezierPath bezierPathWithRect:nextStoryButton.bounds].CGPath;
        nextStoryButton.layer.shadowColor = [BANYAN_DARKGRAY_COLOR CGColor];
        nextStoryButton.layer.masksToBounds = NO;
        
        __weak UIButton *wNextStoryButton = nextStoryButton;
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.nextStory.media];
        [imageMedia getImageForMediaWithSuccess:^(UIImage *image) {
            RUN_SYNC_ON_MAINTHREAD(^{[wNextStoryButton setBackgroundImage:[image applyExtraLightEffect] forState:UIControlStateNormal];});
        } progress:nil failure:nil];
        [self.view addSubview:nextStoryButton];
    }
}

#pragma mark
# pragma mark target actions
- (IBAction)goToStoryList:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate nextStoryViewControllerGoToStoryList:self];
    }];
}

- (IBAction)goToNextStory:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate nextStoryViewControllerGoToStory:self.nextStory];
    }];
}

- (IBAction)addPieceToStory:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self.delegate nextStoryViewControllerAddPieceToStory:self];
    }];
}

# pragma mark
# pragma mark Interaction Controller methods
- (void) interactionControllerDidWireToViewWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    gestureRecognizer.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation NextStoryViewController (UIGestureRecognizerDelegate)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (otherGestureRecognizer == [self.delegate dismissAheadPanGestureRecognizer]) {
        return YES;
    }
    return NO;
}

@end
