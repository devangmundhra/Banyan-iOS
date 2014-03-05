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
    [self setGAIScreenName:@"About Banyan screen"];
    [self prepareForSlidingViewController];
    
    self.title = @"About Banyan";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
