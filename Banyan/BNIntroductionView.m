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
                                                                       title:@"Title 1"
                                                                 description:@"Description 1."];
    
    
    //Create Stock Panel With Image
    MYIntroductionPanel *panel2 = [[MYIntroductionPanel alloc] initWithFrame:frame
                                                                       title:@"Title 2"
                                                                 description:@"Desc 2"];
    
    //Add panels to an array
    NSArray *panels = @[panel1, panel2];
    [self setBackgroundColor:[BANYAN_GREEN_COLOR colorWithAlphaComponent:0.65]];
    //introductionView.LanguageDirection = MYLanguageDirectionRightToLeft;
    
    //Build the introduction with desired panels
    [self buildIntroductionWithPanels:panels];
}

@end