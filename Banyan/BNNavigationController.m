//
//  BNNavigationController.m
//  Banyan
//
//  Created by Devang Mundhra on 2/14/14.
//
//

#import "BNNavigationController.h"

@interface BNNavigationController ()

@end

@implementation BNNavigationController {
    void (^_completion)();
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.delegate = self;
    }
    return self;
}

- (id) initWithRootViewController:(UIViewController *) rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void) navigationController:(UINavigationController *) navigationController didShowViewController:(UIViewController *) viewController animated:(BOOL) animated {
    if (_completion) {
        _completion();
        _completion = nil;
    }
}

- (UIViewController *) popViewControllerAnimated:(BOOL) animated completion:(void (^)()) completion {
    _completion = completion;
    return [super popViewControllerAnimated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
