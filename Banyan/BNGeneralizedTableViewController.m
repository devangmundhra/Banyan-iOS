//
//  BNGeneralizedTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 12/14/13.
//
//

#import "BNGeneralizedTableViewController.h"
#import "Story+Permissions.h"

static NSString *CellIdentifier = @"ContributorNameCell";
@interface BNGeneralizedTableViewController ()

@end

@implementation BNGeneralizedTableViewController
@synthesize dataSource = _dataSource;
@synthesize type = _type;
@synthesize sectionString = _sectionString;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style type:(BNGeneralizedTableViewType)type
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.type = type;
        switch (type) {
            case BNGeneralizedTableViewTypePieceLikers:
                self.tableView.rowHeight = 30;
                break;
                
            default:
                break;
        }
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
    return self.sectionString;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSDictionary *dict = nil;
    switch (self.type) {
        case BNGeneralizedTableViewTypeStoryContributors:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            dict = [self.dataSource objectAtIndex:indexPath.row];
            cell.textLabel.text = [dict objectForKey:kDictionaryInSortedArrayOfContributorsNameKey];
            cell.textLabel.font = [UIFont fontWithName:@"Roboto" size:14];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ pieces", [dict objectForKey:kDictionaryInSortedArrayOfContributorsCountKey]];
            cell.detailTextLabel.textColor = BANYAN_GRAY_COLOR;
            break;
            
        case BNGeneralizedTableViewTypePieceLikers:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            dict = [[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"user"];
            cell.textLabel.text = [dict objectForKey:@"name"];
            cell.textLabel.font = [UIFont fontWithName:@"Roboto" size:14];
            break;

        default:
            break;
    }
    return cell;
}

@end
