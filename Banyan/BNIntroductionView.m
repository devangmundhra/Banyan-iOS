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
                                                                       title:@"Welcome to Banyan!"
                                                                 description:@"Banyan is a tool to help you and people around you capture experiences together."];
    
    
    //Create Stock Panel With Image
    MYIntroductionPanel *panel2 = [[MYIntroductionPanel alloc] initWithFrame:frame
                                                                       title:@"Thanks for helping out!"
                                                                 description:@"Now that you know what Banyan is, we would really love it if you could keep letting us know what can be done to make it more useful for you. We want to be able to provide you the best way to create and share your stories with anyone."];
    
    //Add panels to an array
    NSArray *panels = @[panel1, panel2];
    //introductionView.LanguageDirection = MYLanguageDirectionRightToLeft;
    
    //Build the introduction with desired panels
    [self buildIntroductionWithPanels:panels];
    [self setBackgroundColor:BANYAN_GREEN_COLOR];
}

@end