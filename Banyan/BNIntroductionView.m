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
    MYIntroductionPanel *panel1 = [[MYIntroductionPanel alloc] initWithFrame:frame
                                                                       title:@"Welcome to Banyan!"
                                                                 description:@"Banyan assists you to create your own stories and invite anyone you like to contribute to or view the story. "
                                   "You can also make the stories publicly viewable and contributable, letting your friends and could-be-friends to expand upon it.\r\r"
                                   "Better still, if there is already a story about something you want to add to, share a piece of your thought to it."
                                                                       image:[UIImage imageNamed:@"BNLogo"]];
    
    MYIntroductionPanel *panel2 = [[MYIntroductionPanel alloc] initWithFrame:frame
                                                                       title:@"Almost there..."
                                                                 description:@"To start with, you can read some of the publicly shared stories by users like you."
                                   "To share your own stories, or to see stories to which you might have been invited to, please Sign in.\r\r"
                                   "What you have downloaded is just the beginning of an experiment for a more collaborative online experience. You will surely find some rough edges here and there, on which we are constantly rubbing the sand paper.\r\r "
                                   "We are always eager to hear from you- your thoughts, feedback, complaints and what you would like to see in the app. You can reach us through the feedback tab available in the side menu, or email us at hello@banyan.io"];
    
    //Add panels to an array
    NSArray *panels = @[panel1, panel2];
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