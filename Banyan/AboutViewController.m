//
//  AboutViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/26/13.
//
//

#import "AboutViewController.h"
#import "UIViewController+BNSlidingViewControllerAdditions.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UITextView *aboutTextView;
@end

@implementation AboutViewController

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
    // Do any additional setup after loading the view from its nib.
    [self prepareForSlidingViewController];
    
    const int titleFontSize = 18;
    const int bodyFontSize = 14;
    
    self.title = @"About Banyan";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentJustified;
    
    NSMutableAttributedString *aboutStringFinal = [[NSMutableAttributedString alloc] initWithString:@"Banyan - stories with friends\r\r"
                                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:titleFontSize],
                                                                                                      NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                                      NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle],
                                                                                                      NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                      NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    NSAttributedString *aboutBanyan = [[NSAttributedString alloc] initWithString:@"Banyan is a social collaboration app designed to help make it easier for you to capture and store experiences together with your friends and family instantly, and share it the way you like.\r"
                                       "Whether its a wedding, a road trip with friends, a story of your imagination or just a personal diary, Banyan allows you to write your own, contribute to or browse through those stories that have been shared with you.\r\r"
                                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:bodyFontSize],
                                                                                          NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                          NSParagraphStyleAttributeName: paragraphStyle,
                                                                                          NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:aboutBanyan];
    
    NSAttributedString *whyBanyanTitle = [[NSAttributedString alloc] initWithString:@"With Banyan, you have-\r"
                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:bodyFontSize],
                                                                                      NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                      NSParagraphStyleAttributeName: paragraphStyle,
                                                                                      NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:whyBanyanTitle];
    
    NSAttributedString *privacyControlTitle = [[NSAttributedString alloc] initWithString:@"- Privacy Controls\r"
                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:bodyFontSize],
                                                                                      NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                      NSParagraphStyleAttributeName: paragraphStyle,
                                                                                      NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:privacyControlTitle];
    
    NSAttributedString *privacyControlBody = [[NSAttributedString alloc] initWithString:@"Easily select whom would you like to invite to contribute to a story, and with whom would you like to share.\r\r"
                                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:bodyFontSize],
                                                                                          NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR,
                                                                                          NSParagraphStyleAttributeName: paragraphStyle,
                                                                                          NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:privacyControlBody];

    NSAttributedString *offlineTitle = [[NSAttributedString alloc] initWithString:@"- Use when offline \r"
                                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:bodyFontSize],
                                                                                           NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                           NSParagraphStyleAttributeName: paragraphStyle,
                                                                                           NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:offlineTitle];
    
    NSAttributedString *offlineBody = [[NSAttributedString alloc] initWithString:@"Out camping in the forest with no network? No worries! Keep capturing your experiences through Banyan and it will automatically sync up when there is network.\r\r"
                                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:bodyFontSize],
                                                                                          NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR,
                                                                                          NSParagraphStyleAttributeName: paragraphStyle,
                                                                                          NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:offlineBody];
    
    NSAttributedString *multimediaTitle = [[NSAttributedString alloc] initWithString:@"- Add multi-kinds-of-media\r"
                                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:bodyFontSize],
                                                                                           NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                           NSParagraphStyleAttributeName: paragraphStyle,
                                                                                           NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:multimediaTitle];
    
    NSAttributedString *multimediaBody = [[NSAttributedString alloc] initWithString:@"Add photos (with filters), audio (15 seconds) or text to make the stories more interesting and memorable!\r\r"
                                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:bodyFontSize],
                                                                                          NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR,
                                                                                          NSParagraphStyleAttributeName: paragraphStyle,
                                                                                          NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:multimediaBody];
    
    NSAttributedString *sharingTitle = [[NSAttributedString alloc] initWithString:@"- Different sharing options\r"
                                                                          attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:bodyFontSize],
                                                                                       NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                       NSParagraphStyleAttributeName: paragraphStyle,
                                                                                       NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:sharingTitle];
    
    NSAttributedString *sharingBody = [[NSAttributedString alloc] initWithString:@"Share your story as a photo album on Facebook, or for a richer experience, as a story on banyan.io site.\r\r"
                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:bodyFontSize],
                                                                                      NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR,
                                                                                      NSParagraphStyleAttributeName: paragraphStyle,
                                                                                      NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:sharingBody];
    
    NSAttributedString *feedbackBody = [[NSAttributedString alloc] initWithString:@"We are always eager to hear from you, and to help you make it easier to record and relive your memories with your friends.\r"
                                        "Send us your thoughts and questions at help@banyan.io \r\r"
                                                                      attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:bodyFontSize],
                                                                                   NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                   NSParagraphStyleAttributeName: paragraphStyle,
                                                                                   NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    [aboutStringFinal appendAttributedString:feedbackBody];
    
    self.aboutTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.aboutTextView.attributedText = aboutStringFinal;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"About Banyan screen"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
