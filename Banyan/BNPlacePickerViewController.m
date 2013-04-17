//
//  BNPlacePickerViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 4/15/13.
//
//

#import "BNPlacePickerViewController.h"

@interface BNPlacePickerViewController ()

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation BNPlacePickerViewController

@synthesize searchBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate
{
    [super setLocationCoordinate:locationCoordinate];
    [self loadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.doneButton = nil;
        
    // Search bar
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    /*the search bar widht must be &gt; 1, the height must be at least 44
     (the real size of the search bar)*/
    
    [self.tableView setContentOffset:CGPointZero animated:NO];
    
    self.tableView.tableHeaderView = self.searchBar; // this line adds the searchBar
    //on the top of tableView.
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    [theSearchBar setShowsCancelButton:YES animated:YES];
    //Changed to YES to allow selection when in the middle of a search/filter
    self.tableView.allowsSelection   = YES;
    self.tableView.scrollEnabled     = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [theSearchBar resignFirstResponder];
    self.tableView.allowsSelection   = YES;
    self.tableView.scrollEnabled     = YES;
    theSearchBar.text           = @"";
    
    self.searchText = theSearchBar.text;
    [self updateView];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    self.tableView.allowsSelection   = YES;
    self.tableView.scrollEnabled     = YES;
    
    self.searchText = theSearchBar.text;
    [self loadData];
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText
{
    self.searchText = searchText;
    [self loadData];
}

- (IBAction) cancelButtonPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
