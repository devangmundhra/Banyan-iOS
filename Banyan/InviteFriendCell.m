//
//  InviteFriendCell.m
//  Banyan
//
//  Created by Devang Mundhra on 4/2/13.
//
//

#import "InviteFriendCell.h"
#import "UIImage+Create.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+WebCache.h"

@interface InviteFriendCell ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (weak, nonatomic) IBOutlet UIButton *readButton;
@property (weak, nonatomic) IBOutlet UIButton *writeButton;

@end

@implementation InviteFriendCell
@synthesize nameLabel, readButton, writeButton;
@synthesize delegate, profilePicImageView;

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
    nameLabel.font = [UIFont fontWithName:@"Roboto" size:14];
    nameLabel.backgroundColor = BANYAN_WHITE_COLOR;
    
    // Read button
    [readButton addTarget:self action:@selector(readButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    readButton.exclusiveTouch = YES;
    readButton.backgroundColor = BANYAN_WHITE_COLOR;
    
    // Write button
    [writeButton addTarget:self action:@selector(writeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    writeButton.exclusiveTouch = YES;
    writeButton.backgroundColor = BANYAN_WHITE_COLOR;
    
    CGFloat profilePicSize = 35;
    
    CGRect frame = CGRectMake(10, self.center.y - roundf(profilePicSize/2) - 2, profilePicSize, profilePicSize);
    profilePicImageView.frame = frame;
    
    CALayer *layer = profilePicImageView.layer;
    [layer setCornerRadius:profilePicSize/2];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth:1.0f];
    [layer setBorderColor:[BANYAN_DARKBROWN_COLOR colorWithAlphaComponent:0.4].CGColor];
    profilePicImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
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

- (void) setFriend:(NSDictionary *)fbFriend
{
    NSString *name = [fbFriend objectForKey:@"name"];
    
    NSString *friendId = [fbFriend objectForKey:@"id"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", friendId]];
    UIImage *phImage = [UIImage imageFromText:[BNMisc getInitialsFromName:name]
                                     withFont:[UIFont fontWithName:@"Roboto" size:16]
                                    withColor:BANYAN_DARKBROWN_COLOR];
    
    [profilePicImageView setImageWithURL:url placeholderImage:phImage];
    nameLabel.text = name;
}

- (void) canRead:(BOOL)set
{
    if (set)
        [readButton setImage:[UIImage imageNamed:@"Scroll_selected"] forState:UIControlStateNormal];
    else
        [readButton setImage:[UIImage imageNamed:@"Scroll"] forState:UIControlStateNormal];
}

- (void) canWrite:(BOOL)set
{
    if (set)
        [writeButton setImage:[UIImage imageNamed:@"Pencil_selected"] forState:UIControlStateNormal];
    else
        [writeButton setImage:[UIImage imageNamed:@"Pencil"] forState:UIControlStateNormal];
}

- (void) hideReadWriteButtons:(BOOL)hide
{
    writeButton.hidden = hide;
    readButton.hidden = hide;
}

@end
