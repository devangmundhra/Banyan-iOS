//
//  BNSidePanelController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/25/13.
//
//

#import "BNSidePanelController.h"

@interface BNSidePanelController ()

@end

@implementation BNSidePanelController

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
}

- (UIBarButtonItem *)leftButtonForCenterPanel {
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[[self class] defaultImage] style:UIBarButtonItemStylePlain target:self action:@selector(toggleLeftPanel:)];
    button.tintColor = BANYAN_GREEN_COLOR;
    return button;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
