//
//  BNNotificationsTableViewCell.m
//  Banyan
//
//  Created by Devang Mundhra on 6/3/14.
//
//

#import "BNNotificationsTableViewCell.h"
#import "NSString+FontAwesome.h"

// Same from xib file
CGFloat const BNNotificationsTableViewCellHeight = 34.0f;

NSString *const kBNNotificationTypeLike = @"like";
NSString *const kBNNotificationTypeFollow = @"follow";
NSString *const kBNNotificationTypeJoin = @"join";
NSString *const kBNNotificationTypeStoryStart = @"story_start";
NSString *const kBNNotificationTypePieceAdded = @"piece_add";
NSString *const kBNNotificationTypeViewInvite = @"view_inv";
NSString *const kBNNotificationTypeContribInvite = @"contrib_inv";

@interface BNNotificationsTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *symbolLabel;
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation BNNotificationsTableViewCell
@synthesize notification = _notification;
@synthesize symbolLabel, activityLabel, dateLabel;

- (void)awakeFromNib
{
    // Initialization code
    self.backgroundColor = BANYAN_CLEAR_COLOR;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    self.symbolLabel.font = [UIFont fontWithName:@"FontAwesome" size:12];
    self.symbolLabel.backgroundColor = BANYAN_CLEAR_COLOR;
    
    self.activityLabel.font = [UIFont fontWithName:@"Roboto" size:10];
    self.activityLabel.textColor = BANYAN_WHITE_COLOR;
    self.activityLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.activityLabel.backgroundColor = BANYAN_CLEAR_COLOR;
    
    self.dateLabel.font = [UIFont fontWithName:@"Roboto" size:8];
    self.dateLabel.textColor = BANYAN_LIGHTGRAY_COLOR;
    self.dateLabel.backgroundColor = BANYAN_CLEAR_COLOR;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setNotification:(NSDictionary *)notification
{
    _notification = notification;
    
    self.activityLabel.text = [notification objectForKey:@"description"];
    
    NSString *stringDate = [notification objectForKey:@"createdAt"];
    NSDate *createdDate = [[BNMisc pythonISODateFormatter] dateFromString:stringDate];
    self.dateLabel.text = [[BNMisc dateFormatterShortTimeMediumDateRelative] stringFromDate:createdDate];
    
    NSString *type = [notification objectForKey:@"type"];
    
    if ([type isEqualToString:kBNNotificationTypeLike]) {
        self.symbolLabel.text = [NSString fa_stringForFontAwesomeIcon:FAHeart];
        self.symbolLabel.textColor = BANYAN_PINK_COLOR;
    } else if ([type isEqualToString:kBNNotificationTypeFollow]) {
        self.symbolLabel.text = [NSString fa_stringForFontAwesomeIcon:FAUsers];
        self.symbolLabel.textColor = BANYAN_CREAM_COLOR;
    } else if ([type isEqualToString:kBNNotificationTypeJoin]) {
        self.symbolLabel.text = [NSString fa_stringForFontAwesomeIcon:FAChain];
        self.symbolLabel.textColor = BANYAN_LIGHT_GREEN_COLOR;
    } else if ([type isEqualToString:kBNNotificationTypeStoryStart]) {
        self.symbolLabel.text = [NSString fa_stringForFontAwesomeIcon:FABook];
        self.symbolLabel.textColor = BANYAN_DARK_GREEN_COLOR;
    } else if ([type isEqualToString:kBNNotificationTypePieceAdded]) {
        self.symbolLabel.text = [NSString fa_stringForFontAwesomeIcon:FAPlus];
        self.symbolLabel.textColor = BANYAN_DARK_GREEN_COLOR;
    } else if ([type isEqualToString:kBNNotificationTypeViewInvite]) {
        self.symbolLabel.text = [NSString fa_stringForFontAwesomeIcon:FAEye];
        self.symbolLabel.textColor = BANYAN_GREEN_COLOR;
    } else if ([type isEqualToString:kBNNotificationTypeContribInvite]) {
        self.symbolLabel.text = [NSString fa_stringForFontAwesomeIcon:FAEdit];
        self.symbolLabel.textColor = BANYAN_GREEN_COLOR;
    } else {
        self.symbolLabel.text = nil;
    }
}

@end
