//
//  UIViewController+GoogleAnalytics.m
//  Banyan
//
//  Created by Devang Mundhra on 3/4/14.
//
//

#import "UIViewController+GoogleAnalytics.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation UIViewController (GoogleAnalytics)

- (void)setGAIScreenName:(NSString *)screenName
{
    // May return nil if a tracker has not already been initialized with a
    // property ID.
    id tracker = [[GAI sharedInstance] defaultTracker];
    
    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
    [tracker set:kGAIScreenName
           value:screenName];
    
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

@end
