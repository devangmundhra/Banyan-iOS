//
//  ContributorsTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 12/14/13.
//
//

#import "ContributorsTableViewController.h"
#import "Story+Permissions.h"

static NSString *CellIdentifier = @"ContributorNameCell";
@interface ContributorsTableViewController ()

@end

@implementation ContributorsTableViewController
@synthesize dataSource = _dataSource;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.dataSource.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Contributors";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSDictionary *dict = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = [dict objectForKey:kDictionaryInSortedArrayOfContributorsNameKey];
    cell.textLabel.font = [UIFont fontWithName:@"Roboto" size:14];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ pieces", [dict objectForKey:kDictionaryInSortedArrayOfContributorsCountKey]];
    cell.detailTextLabel.textColor = BANYAN_GRAY_COLOR;
    return cell;
}

@end
