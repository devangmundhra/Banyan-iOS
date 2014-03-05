//
//  ProfileViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/26/13.
//
//

#import "ProfileViewController.h"
#import "BanyanAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+BNSlidingViewControllerAdditions.h"
#import "AFBanyanAPIClient.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *numStoriesLabel;
@property (weak, nonatomic) IBOutlet UILabel *numPiecesLabel;
@property (weak, nonatomic) IBOutlet UIImageView *globeImage;
@end

@implementation ProfileViewController
@synthesize scrollView = _scrollView;
@synthesize user = _user;

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
    
    self.navigationController.navigationBar.translucent = YES;

    NSNumber *userId = nil;
    if (self.user) {
        self.title = self.user.name;
        userId = self.user.userId;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    } else {
        BNSharedUser *currentUser = [BNSharedUser currentUser];
        self.title = currentUser.name;
        userId = currentUser.userId;
        
        UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign out" style:UIBarButtonItemStyleBordered target:self action:@selector(logoutButtonPressed:)];
        self.navigationItem.rightBarButtonItem = rightBarButtonItem;
        // If there is no self.user, that means we came here via the SideNavigatorViewController.
        // So set up the left bar button item.
        [self prepareForSlidingViewController];
    }
    
    self.nameLabel.text = self.title;
    
    // Setup the different views
    CALayer *layer = self.profileImageView.layer;
    [layer setCornerRadius:35.0f];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth:1.0f];
    [layer setBorderColor:[BANYAN_WHITE_COLOR colorWithAlphaComponent:0.4].CGColor];
    
    [self.nameLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:14]];
    self.nameLabel.textColor = BANYAN_WHITE_COLOR;
    [self.locationLabel setFont:[UIFont fontWithName:@"Roboto" size:14]];
    self.locationLabel.textColor = BANYAN_WHITE_COLOR;
    
    layer = self.numStoriesLabel.layer;
    [layer setBorderWidth:0.5f];
    [layer setBorderColor:BANYAN_GRAY_COLOR.CGColor];
    layer = self.numPiecesLabel.layer;
    [layer setBorderWidth:0.5f];
    [layer setBorderColor:BANYAN_GRAY_COLOR.CGColor];
    
    // Fetch the information and update the UI with the information
    [[AFBanyanAPIClient sharedClient] getPath:[NSString stringWithFormat:@"users/%@/?format=json", userId]
                                   parameters:nil
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *userDetails = [responseObject objectForKey:@"user_details"];
                                          [self.coverImageView setImageWithURL:[NSURL URLWithString:REPLACE_NULL_WITH_NIL([userDetails objectForKey:@"cover"])]];
                                          [self.profileImageView setImageWithURL:[NSURL URLWithString:REPLACE_NULL_WITH_NIL([userDetails objectForKey:@"picture"])]];
                                          self.locationLabel.text = REPLACE_NULL_WITH_NIL([userDetails objectForKey:@"location"]);
                                          if (self.locationLabel.text) {
                                              self.globeImage.hidden = NO;
                                          } else {
                                              self.globeImage.hidden = YES;
                                          }
                                          NSDictionary *usageDetails = [responseObject objectForKey:@"usage_details"];
                                          NSNumber *numStories = [usageDetails objectForKey:@"num_stories"];
                                          NSNumber *numPieces = [usageDetails objectForKey:@"num_pieces"];
                                          
                                          NSAttributedString *numString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", numStories]
                                                                                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14],
                                                                                                                         NSForegroundColorAttributeName: BANYAN_BLACK_COLOR}];
                                          NSAttributedString *objString = [[NSAttributedString alloc] initWithString:@"\rStories"
                                                                                                                  attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                                                               NSForegroundColorAttributeName: BANYAN_BLACK_COLOR}];
                                          NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithAttributedString:numString];
                                          [attrString appendAttributedString:objString];
                                          self.numStoriesLabel.attributedText = attrString;
                                          
                                          numString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", numPieces]
                                                                                                          attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14],
                                                                                                                       NSForegroundColorAttributeName: BANYAN_BLACK_COLOR}];
                                          objString = [[NSAttributedString alloc] initWithString:@"\rPieces"
                                                                                                          attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                                                       NSForegroundColorAttributeName: BANYAN_BLACK_COLOR}];
                                          attrString = [[NSMutableAttributedString alloc] initWithAttributedString:numString];
                                          [attrString appendAttributedString:objString];
                                          self.numPiecesLabel.attributedText = attrString;
                                      }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          [[[UIAlertView alloc] initWithTitle:@"Cannot get user info"
                                                                      message:[NSString stringWithFormat:@"Error %@ in getting information about user %@", error.localizedDescription, self.title]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil] show];
                                      }];
    
    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width,
                                             screenSize.height);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Profile view"];
}

- (IBAction)logoutButtonPressed:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate logout];
}

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
