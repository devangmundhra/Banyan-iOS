//
//  BNNotificationsView.m
//  Banyan
//
//  Created by Devang Mundhra on 6/2/14.
//
//

#import "BNNotificationsView.h"
#import "BanyanConnection.h"
#import "MBProgressHUD.h"

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *notification = [self.notifications objectAtIndex:indexPath.row];
    
    NSString *object_uri = [notification objectForKey:@"content_object"];
    if ([object_uri isEqual:[NSNull null]] || !object_uri.length) {
        BNLogWarning(@"%@ has no content object", notification);
        return;
    }
    
    NSString *type = [notification objectForKey:@"type"];

    if (   [type isEqualToString:kBNNotificationTypeLike]
        || [type isEqualToString:kBNNotificationTypePieceAdded]) {
        // show piece
        [self showPieceWithUri:object_uri];
    } else if (   [type isEqualToString:kBNNotificationTypeFollow]
               || [type isEqualToString:kBNNotificationTypeStoryStart]
               || [type isEqualToString:kBNNotificationTypeViewInvite]
               || [type isEqualToString:kBNNotificationTypeContribInvite]) {
        // show story
        [self showStoryWithUri:object_uri];
    } else if ([type isEqualToString:kBNNotificationTypeJoin]) {
        // show user
        [self showUserWithUri:object_uri];
    } else {
        // nothing
    }
}

- (void) showStoryWithUri:(NSString *)uri
{
    __weak typeof(self) wself = self;
    void (^completionCallback)(Story *) = ^(Story *story) {
        if (story.pieces.count) {
            Piece *piece = [story.pieces objectAtIndex:0];
            [wself.delegate notificationView:wself didSelectStory:story piece:piece];
        }
    };
    
    // Check if a story already exists with that Uri
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kBNStoryClassKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(resourceUri == %@)", uri];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    Story *story = array.count ? [array objectAtIndex:0] : nil;
    
    if (story) {
        completionCallback(story);
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Fetching story from the server";
        hud.labelFont = [UIFont fontWithName:@"Roboto" size:12];
        __weak typeof(hud) whud = hud;
        
        NSString *storyId = [BNMisc getObjectIdFromResourceUri:uri];
        [BanyanConnection loadStoryWithId:storyId
                               withParams:nil
                          completionBlock:^(Story *story) {
                              completionCallback(story);
                              RUN_SYNC_ON_MAINTHREAD(^{[whud hide:YES];});
                          }
                               errorBlock:^(NSError *error) {
                                   [BNMisc sendGoogleAnalyticsError:error inAction:@"Story notification" isFatal:NO];
                                   RUN_SYNC_ON_MAINTHREAD(^{
                                       whud.mode = MBProgressHUDModeText;
                                       whud.labelText = @"Error in fetching story";
                                       [whud hide:YES afterDelay:2];
                                   });
                               }];
    }
}

- (void) showPieceWithUri:(NSString *)uri
{
    __weak typeof(self) wself = self;
    void (^completionCallback)(Piece *) = ^(Piece *piece) {
        [wself.delegate notificationView:wself didSelectStory:piece.story piece:piece];
    };
    
    // Check if a story already exists with that Uri
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kBNPieceClassKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(resourceUri == %@)", uri];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    Piece *piece = array.count ? [array objectAtIndex:0] : nil;
    
    if (piece) {
        completionCallback(piece);
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Fetching piece from the server";
        hud.labelFont = [UIFont fontWithName:@"Roboto" size:12];
        __weak typeof(hud) whud = hud;
        
        NSString *pieceId = [BNMisc getObjectIdFromResourceUri:uri];
        [BanyanConnection loadPieceWithId:pieceId
                               withParams:nil
                          completionBlock:^(Piece *piece) {
                              completionCallback(piece);
                              RUN_SYNC_ON_MAINTHREAD(^{[whud hide:YES];});
                          }
                               errorBlock:^(NSError *error) {
                                   [BNMisc sendGoogleAnalyticsError:error inAction:@"Piece notification" isFatal:NO];
                                   RUN_SYNC_ON_MAINTHREAD(^{
                                       whud.mode = MBProgressHUDModeText;
                                       whud.labelText = @"Error in fetching piece";
                                       [whud hide:YES afterDelay:2];
                                   });                               }];
    }
}

- (void) showUserWithUri:(NSString *)uri
{
    __weak typeof(self) wself = self;
    void (^completionCallback)(User *) = ^(User *user) {
        [wself.delegate notificationView:wself didSelectUser:user];
    };
    
    // Check if a story already exists with that Uri
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kBNUserClassKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(resourceUri == %@)", uri];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    User *user = array.count ? [array objectAtIndex:0] : nil;
    
    if (FALSE && user) {
        completionCallback(user);
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Fetching user information from the server";
        hud.labelFont = [UIFont fontWithName:@"Roboto" size:12];
        __weak typeof(hud) whud = hud;
        
        NSString *userId = [BNMisc getObjectIdFromResourceUri:uri];
        [BanyanConnection loadUserWithId:userId
                               withParams:nil
                          completionBlock:^(User *user) {
                              completionCallback(user);
                              RUN_SYNC_ON_MAINTHREAD(^{[whud hide:YES];});
                          }
                               errorBlock:^(NSError *error) {
                                   [BNMisc sendGoogleAnalyticsError:error inAction:@"User notification" isFatal:NO];
                                   RUN_SYNC_ON_MAINTHREAD(^{
                                       whud.mode = MBProgressHUDModeText;
                                       whud.labelText = @"Error in fetching user information";
                                       [whud hide:YES afterDelay:2];
                                   });
                               }];
    }
}
@end
