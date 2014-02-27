//
//  BNIntroductionView.m
//  Banyan
//
//  Created by Devang Mundhra on 11/6/13.
//
//

#import "BNIntroductionView.h"

@implementation BNIntroductionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self buildIntroWithFrame:frame];
    }
    return self;
}

#pragma mark - Build MYBlurIntroductionView

-(void)buildIntroWithFrame:(CGRect)frame
{
    //Create Stock Panel with header
    MYIntroductionPanel *panel1 = [[MYIntroductionPanel alloc] initWithFrame:frame
                                                                       title:@"Welcome!"
                                                                 description:@"\"Man is by nature a social animal...\" ~ Aristotle\r\r"
                                   "We progress by taking somebody's imagination, and improve upon it to create something even better than what we started with.\r\r"
                                   "But when we record our experiences and imaginations, we do it kinda alone - on our phones, on our own albums, in our own silos.\r\r"
                                   "At Banyan, we understand that a person can have many stories to tell. But we think it might be just a little more fun telling the stories together!"];
    
    //Create Stock Panel With Image
    MYIntroductionPanel *panel2 = [[MYIntroductionPanel alloc] initWithFrame:frame
                                                                       title:@"Banyan"
                                                                 description:@"Banyan assists you to create your own stories and invite anyone you like to contribute to or view the story. "
                                   "You can also make the stories publicly viewable and contributable, letting your friends and could-be-friends to expand upon it.\r\r"
                                   "Better still, if there is already a story about something you want to add to, share a piece of your thought to it."
                                                                       image:[UIImage imageNamed:@"BNLogo"]];
    
    MYIntroductionPanel *panel3 = [[MYIntroductionPanel alloc] initWithFrame:frame
                                                                       title:@"Almost there..."
                                                                 description:@"To start with, you can read some of the publicly shared stories by some of the Banyan users."
                                   "You might have been invited to more stories by your friends, but you will only find it out once you sign in!\r\r"
                                   "What you have downloaded is just the beginning of an experiment. You will surely find some rough edges here and there. "
                                   "We are however, constantly rubbing sandpaper on those edges.\r\r"
                                   "Let us know your thoughts through the feedback tab available in the side menu, or email us at hello@banyan.io"];
    
    //Add panels to an array
    NSArray *panels = @[panel1, panel2, panel3];
    //introductionView.LanguageDirection = MYLanguageDirectionRightToLeft;
    
    //Build the introduction with desired panels
    [self buildIntroductionWithPanels:panels];

    self.BackgroundImageView.image =  [UIImage imageNamed:@"IntroBkg2"];
    [self setBackgroundColor:[BANYAN_WHITE_COLOR colorWithAlphaComponent:0.5]];
    panel1.PanelTitleLabel.textColor = BANYAN_BLACK_COLOR;
    panel1.PanelDescriptionLabel.textColor = BANYAN_BLACK_COLOR;
    panel1.PanelTitleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:24];
    panel1.PanelDescriptionLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:14];

}

@end