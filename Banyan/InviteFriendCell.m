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
    [self setup];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

# pragma mark Instance methods

- (void) setup
{
    // Read button
    [readButton addTarget:self action:@selector(readButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Write button
    [writeButton addTarget:self action:@selector(writeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)enableReadButton:(BOOL)set
{
    readButton.enabled = set;
    // If there is public/limited write permission, read button will have that scope of permission too
    if (!writeButton.enabled)
        readButton.enabled = NO;
    if (!readButton.enabled)
        [self canRead:YES];
}

- (void)enableWriteButton:(BOOL)set
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
        [readButton setImage:[UIImage imageNamed:@"readButtonSelected"] forState:UIControlStateNormal];
    else
        [readButton setImage:[UIImage imageNamed:@"readButtonUnselected"] forState:UIControlStateNormal];
}

- (void) canWrite:(BOOL)set
{
    if (set)
        [writeButton setImage:[UIImage imageNamed:@"writeButtonSelected"] forState:UIControlStateNormal];
    else
        [writeButton setImage:[UIImage imageNamed:@"writeButtonUnselected"] forState:UIControlStateNormal];
}

@end
