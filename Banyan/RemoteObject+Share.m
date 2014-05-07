//
//  RemoteObject+Share.m
//  Banyan
//
//  Created by Devang Mundhra on 12/26/13.
//
//

#import "RemoteObject+Share.h"
#import "BanyanAppDelegate.h"
#import "MBProgressHUD.h"
#import "AFBanyanAPIClient.h"

@implementation RemoteObject (Share)
- (void) shareOnFacebookWithName:(NSString *)name
                         caption:(NSString *)caption
                     description:(NSString *)description
                           image:(UIImage *)image
                      pictureURL:(NSString *)pictureURL
                       shareLink:(NSString *)urlToShare
               completionHandler:(void (^)(NSError *error))handler
{
    NSString *message = nil;
    if (caption) {
        message = [NSString stringWithString:caption];
        if (description)
            message = [message stringByAppendingFormat:@"\r%@", description];
    }
    else if (description) {
        message = [NSString stringWithString:description];
    }
    
    // This code demonstrates 3 different ways of sharing using the Facebook SDK.
    // The first method tries to share via Facebook's iOS6 integration, which also
    // allows sharing without the user having to authorize your app, and is available as
    // long as the user has linked their Facebook account with iOS6. This publish will
    // result in a popup iOS6 dialog.
    // The second method tries to share via the Facebook app. This allows sharing without
    // the user having to authorize your app, and is available as long as the user has the
    // correct Facebook app installed. This publish will result in a fast-app-switch to the
    // Facebook app.
    // The third method tries to share via a Graph API request. This does require the user
    // to authorize your app. They must also grant your app publish permissions. This
    // allows the app to publish without any user interaction.
    
    // First try to post using Facebook's iOS6 integration
    if ([FBDialogs canPresentOSIntegratedShareDialogWithSession:nil]) {
        [FBDialogs presentOSIntegratedShareDialogModallyFrom:APP_DELEGATE.topMostController
                                                 initialText:message
                                                       image:image
                                                         url:[NSURL URLWithString:urlToShare]
                                                     handler:^(FBOSIntegratedShareDialogResult result, NSError *error) {
                                                         handler(error);
                                                         if (error) {
                                                             [self showErrorAlert:error];
                                                         }
                                                     }];
    }
    else {
        // If it is available, we will next try to post using the share dialog in the Facebook app
        FBAppCall *appCall = [FBDialogs presentShareDialogWithLink:[NSURL URLWithString:urlToShare]
                                                              name:name
                                                           caption:caption
                                                       description:description
                                                           picture:[NSURL URLWithString:pictureURL]
                                                       clientState:nil
                                                           handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                               handler(error);
                                                               if (error) {
                                                                   [self showErrorAlert:error];
                                                               }
                                                           }];
        
        if (!appCall) {
            [self performFacebookPublishAction:^(NSError *error){
                if (error) {
                    handler(error);
                    return;
                }
                // Lastly, fall back on a request for permissions and a direct post using the Graph API
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               REPLACE_NIL_WITH_EMPTY_STRING(name), @"name",
                                               REPLACE_NIL_WITH_EMPTY_STRING(caption), @"caption",
                                               REPLACE_NIL_WITH_EMPTY_STRING(description), @"description",
                                               REPLACE_NIL_WITH_EMPTY_STRING(urlToShare), @"link",
                                               REPLACE_NIL_WITH_EMPTY_STRING(pictureURL), @"picture",
                                               nil];
                
                FBRequestConnection *requestConnection = [[FBRequestConnection alloc] init];
                requestConnection.errorBehavior = FBRequestConnectionErrorBehaviorRetry
                | FBRequestConnectionErrorBehaviorReconnectSession | FBRequestConnectionErrorBehaviorAlertUser;
                
                FBRequest *request = [FBRequest requestWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST"];
                [requestConnection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    handler(error);
                }];
                // Even though this method is always called on the main thread, still do a dispatch_async.
                // For some reason, the thread gets hung here otherwise.
                // Maybe [requestConnection start] does a dispatch_sync on the main thread?
                dispatch_async(dispatch_get_main_queue(), ^{
                    [requestConnection start];

                });
            }];
        }
    }
}

- (void)shareOnFacebook
{
    NSAssert(false, @"No share method for the child object");
}

// Convenience method to perform some action that requires the "publish_actions" and "publish_stream" permissions.
- (void) performFacebookPublishAction:(void (^)(NSError *error)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound || [FBSession.activeSession.permissions indexOfObject:@"publish_stream"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions", @"publish_stream"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                action(error);
                                            }];
    } else {
        action(nil);
    }
}

- (void) performFacebookUserPhotosAction:(void (^)(NSError *error)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"user_photos"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession requestNewPublishPermissions:@[@"user_photos"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                action(error);
                                            }];
    } else {
        action(nil);
    }
}

// UIAlertView helper for post buttons
- (void)showErrorAlert:(NSError *)error
{
    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertTitle = @"Error";
        // For simplicity, we will use any error message provided by the SDK,
        // but you may consider inspecting the fberrorShouldNotifyUser or
        // fberrorCategory to provide better recourse to users. See the Scrumptious
        // sample for more examples on error handling.
        if (error.fberrorUserMessage) {
            alertMsg = error.fberrorUserMessage;
        } else {
            alertMsg = @"Operation failed due to a connection problem, retry later.";
        }
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:alertMsg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) flaggedWithMessage:(NSString *)message
{
    BNLogInfo(@"Flagging object %@ with message: %@", self.bnObjectId, message);
    [[AFBanyanAPIClient sharedClient] postPath:@"flag_object/"
                                    parameters:@{@"content_object":self.resourceUri, @"message":message}
                                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                           [self remove];
                                           BNLogTrace(@"Object flagged");
                                       }
                                       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           [BNMisc sendGoogleAnalyticsError:error inAction:@"Flag Story" isFatal:NO];
                                           BNLogError(@"An error occurred: %@", error.localizedDescription);
                                       }];
}
@end
