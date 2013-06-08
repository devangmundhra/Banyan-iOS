//
//  BNTabBarController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/16/13.
//
//

#import "BNTabBarController.h"

@interface BNTabBarController ()

@property (nonatomic, strong) UIButton *centerButton;

@end

@implementation BNTabBarController
@synthesize centerButton = _centerButton;

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
}

- (void) addCenterButtonWithImage:(UIImage *)image andTarget:(id)target withAction:(SEL)action
{
    self.centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.centerButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    self.centerButton.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    [self.centerButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [self.centerButton setBackgroundImage:image forState:UIControlStateNormal];
    
    CGFloat heightDifference = image.size.height - self.tabBar.frame.size.height;
    if (heightDifference < 0)
        self.centerButton.center = self.tabBar.center;
    else
    {
        CGPoint center = self.tabBar.center;
        center.y = center.y - heightDifference/2.0;
        self.centerButton.center = center;
    }
    self.centerButton.showsTouchWhenHighlighted = YES;
    [self.view addSubview:self.centerButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.centerButton && ![self.centerButton superview])
        [self.view addSubview:self.centerButton];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.centerButton && [self.centerButton superview])
        [self.centerButton removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
