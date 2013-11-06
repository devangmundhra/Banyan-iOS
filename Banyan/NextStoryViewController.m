//
//  NextStoryViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 11/5/13.
//
//

#import "NextStoryViewController.h"
#import "Story+Permissions.h"

@interface NextStoryViewController (UIGestureRecognizerDelegate) <UIGestureRecognizerDelegate>

@end

@interface NextStoryViewController ()
@property (weak, nonatomic) IBOutlet UILabel *endStoryMsgLabel;
@property (weak, nonatomic) IBOutlet UILabel *whatNextMsgLabel;

@property (weak, nonatomic) IBOutlet UIButton *storyListButton;
@property (weak, nonatomic) IBOutlet UIButton *nextStoryButton;
@property (weak, nonatomic) IBOutlet UIButton *addPieceButton;

@end

@implementation NextStoryViewController
@synthesize delegate = _delegate;
@synthesize endStoryMsgLabel = _endStoryMsgLabel;
@synthesize whatNextMsgLabel = _whatNextMsgLabel;
@synthesize storyListButton = _storyListButton;
@synthesize nextStoryButton = _nextStoryButton;
@synthesize addPieceButton = _addPieceButton;
@synthesize nextStory = _nextStory;
@synthesize currentStory = _currentStory;

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
#define CORNER_RADIUS 15.0f
#define BORDER_WIDTH   3.0f
#define TEXT_SIDE_INSETS 8.0f
#define TEXT_SPACE_INSETS 10.0f
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.endStoryMsgLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:16];
    self.endStoryMsgLabel.textColor = BANYAN_BLACK_COLOR;
    
    self.whatNextMsgLabel.font = [UIFont fontWithName:@"Roboto" size:16];
    self.whatNextMsgLabel.textColor = BANYAN_BLACK_COLOR;
    
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.alignment = NSTextAlignmentCenter;
    CALayer *layer = nil;
    
    // Story List Button
    layer = self.storyListButton.layer;
    layer.cornerRadius = CORNER_RADIUS;
    [layer setMasksToBounds:YES];
    layer.borderWidth = BORDER_WIDTH;
    layer.borderColor = BANYAN_GREEN_COLOR.CGColor;
    self.storyListButton.contentEdgeInsets = UIEdgeInsetsMake(TEXT_SPACE_INSETS, TEXT_SIDE_INSETS, TEXT_SPACE_INSETS, TEXT_SIDE_INSETS);
    self.storyListButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.storyListButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.storyListButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"<< Go back to Story List\r"
                                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                                          NSForegroundColorAttributeName: BANYAN_GREEN_COLOR,}]
                                    forState:UIControlStateNormal];
    
    if (self.nextStory) {
        // Next Story Button
        layer = self.nextStoryButton.layer;
        layer.cornerRadius = CORNER_RADIUS;
        [layer setMasksToBounds:YES];
        layer.borderWidth = BORDER_WIDTH;
        layer.borderColor = BANYAN_GREEN_COLOR.CGColor;
        self.nextStoryButton.titleLabel.numberOfLines = 0;
        self.nextStoryButton.contentEdgeInsets = UIEdgeInsetsMake(TEXT_SPACE_INSETS, 2*TEXT_SIDE_INSETS, TEXT_SPACE_INSETS, 2*TEXT_SIDE_INSETS);
        self.nextStoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.nextStoryButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        NSMutableAttributedString *nextStoryString = [[NSMutableAttributedString alloc] initWithString:@"Go to next Story >\r"
                                                                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                                                         NSForegroundColorAttributeName: BANYAN_GREEN_COLOR,}];
        NSAttributedString *storyTitleString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\r", self.nextStory.title]
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:14],
                                                                                                                NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,}];
        NSAttributedString *storyContributorString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"by %@", [self.nextStory shortStringOfContributors]]
                                                                               attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:12],
                                                                                            NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR,}];
        
        [nextStoryString appendAttributedString:storyTitleString];
        [nextStoryString appendAttributedString:storyContributorString];
        [nextStoryString addAttribute:NSParagraphStyleAttributeName value:paraStyle
                                range:NSMakeRange(0, [nextStoryString string].length)];
        [self.nextStoryButton setAttributedTitle:nextStoryString
                                        forState:UIControlStateNormal];
    } else {
        self.nextStoryButton.hidden = YES;
    }

    
    if (self.currentStory.canContribute) {
        // Add piece to story button
        layer = self.addPieceButton.layer;
        layer.cornerRadius = CORNER_RADIUS;
        [layer setMasksToBounds:YES];
        layer.borderWidth = BORDER_WIDTH;
        layer.borderColor = BANYAN_GREEN_COLOR.CGColor;
        self.addPieceButton.contentEdgeInsets = UIEdgeInsetsMake(TEXT_SPACE_INSETS, TEXT_SIDE_INSETS, TEXT_SPACE_INSETS, TEXT_SIDE_INSETS);
        self.addPieceButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.addPieceButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [self.addPieceButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"+ Add a piece to this story"
                                                                                attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                                             NSForegroundColorAttributeName: BANYAN_GREEN_COLOR,}]
                                       forState:UIControlStateNormal];
    } else {
        self.addPieceButton.hidden = YES;
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
