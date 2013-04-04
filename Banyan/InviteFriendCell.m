//
//  InviteFriendCell.m
//  Banyan
//
//  Created by Devang Mundhra on 4/2/13.
//
//

#import "InviteFriendCell.h"

@interface InviteFriendCell ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *readButton;
@property (weak, nonatomic) IBOutlet UIButton *writeButton;

@end

@implementation InviteFriendCell
@synthesize nameLabel, readButton, writeButton;
@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [readButton addTarget:self action:@selector(readButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [writeButton addTarget:self action:@selector(writeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setBackgroundColor:[UIColor clearColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

# pragma mark Instance methods
- (void)disableReadButton:(BOOL)set
{
    readButton.enabled = set;
    // If there is public/limited write permission, read button will have that scope of permission too
    if (!writeButton.enabled)
        readButton.enabled = NO;
    if (!readButton.enabled)
        [self canRead:YES];
}

- (void)disableWriteButton:(BOOL)set
{
    writeButton.enabled = set;
    if (!writeButton.enabled)
        [self canWrite:YES];
}

-(void)readButtonTapped:(id)sender
{
    if (delegate) {
        [delegate inviteFriendCellReadButtonTapped:self];
    }
}

-(void)writeButtonTapped:(id)sender
{
    if (delegate) {
        [delegate inviteFriendCellWriteButtonTapped:self];
    }
}

- (void) setName:(NSString *)name
{
    nameLabel.text = name;
}

- (void) canRead:(BOOL)set
{
    if (set)
        [readButton setTitle:@"R" forState:UIControlStateNormal];
    else
        [readButton setTitle:@"nr" forState:UIControlStateNormal];
}

- (void) canWrite:(BOOL)set
{
    if (set)
        [writeButton setTitle:@"W" forState:UIControlStateNormal];
    else
        [writeButton setTitle:@"nw" forState:UIControlStateNormal];
}

@end
