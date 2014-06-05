//
//  BNNotificationsView.m
//  Banyan
//
//  Created by Devang Mundhra on 6/2/14.
//
//

#import "BNNotificationsView.h"

static NSString *CellIdentifier = @"BNNotificationsViewCell";

@interface BNNotificationsView () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@end

@implementation BNNotificationsView
@synthesize tableView = _tableView;
@synthesize notifications = _notifications;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    self.backgroundColor = [BANYAN_DARKBROWN_COLOR colorWithAlphaComponent:0.7];
    self.tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = BANYAN_CLEAR_COLOR;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorColor = BANYAN_BROWN_COLOR;
    self.tableView.rowHeight = BNNotificationsTableViewCellHeight;
    [self.tableView registerNib:[UINib nibWithNibName:@"BNNotificationsTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.scrollEnabled = NO;
    [self addSubview:self.tableView];
}

- (void)setNotifications:(NSArray *)notifications
{
    _notifications = notifications;
    [self.tableView reloadData];
}

#pragma mark TableView delegate methods
- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 2;
}

#pragma mark TableView datasource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BNNotificationsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"BNNotificationsTableViewCell" owner:self options:nil];
        cell = (BNNotificationsTableViewCell *)[nibs objectAtIndex:0];
    }

    cell.notification = [self.notifications objectAtIndex:indexPath.row];

    return cell;
}


@end
