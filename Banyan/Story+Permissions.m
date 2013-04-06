//
//  Story+Permissions.m
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Story+Permissions.h"
#import "AFBanyanAPIClient.h"
#import <Parse/Parse.h>

@implementation Story (Permissions)

# pragma mark Permissions management
- (void) resetPermission
{
    self.isInvited = NO;
    self.canContribute = NO;
    self.canView = NO;
    
    if (![PFUser currentUser]) {
        NSLog(@"%s No current user", __PRETTY_FUNCTION__);
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"json", @"format", self.bnObjectId, @"object_id", [PFUser currentUser].objectId, @"user_id", nil];
    
    [[AFBanyanAPIClient sharedClient] getPath:BANYAN_API_GET_PERMISSIONS(@"Story")
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          self.canContribute = [results objectForKey:@"write"];
                                          self.canView = [results objectForKey:@"read"];
                                          self.isInvited = [results objectForKey:@"invited"];
                                      }
                                      failure:AF_BANYAN_ERROR_BLOCK()];
    
    return;
}

@end
