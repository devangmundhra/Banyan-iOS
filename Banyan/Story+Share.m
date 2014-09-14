//
//  Story+Share.m
//  Banyan
//
//  Created by Devang Mundhra on 12/26/13.
//
//

#import "Story+Share.h"
#import "Media+Transfer.h"
#import "User.h"
#import "Piece.h"

NSString *const shareAsLinkOnFacebookString = @"Share as a link on Facebook";
NSString *const shareAsNewFbAlbumString = @"Share as a new Facebook album";
NSString *const copyLinkToStoryString = @"Copy link to story";

@interface Story (UIActionSheetDelegate) <UIActionSheetDelegate>
@end

@implementation Story (Share)

- (void) shareOnFacebook
{
    UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:@"How would you like to share this story" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:shareAsLinkOnFacebookString, shareAsNewFbAlbumString, copyLinkToStoryString, nil];
    
    [shareSheet showInView:APP_DELEGATE.topMostController.view];
}

- (void) shareAsAlbumOnFacebook
{
    // NOTE: FBRequestConnection should always be executed in the main thread!
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
    hud.labelText = @"Sharing story";
    hud.detailsLabelText = [NSString stringWithFormat:@"Uploading the story %@ on Facebook as an album", self.title];
    void (^completionHandler)(NSError *) = ^(NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud setMode:MBProgressHUDModeText];
            if (!error) {
                hud.labelText = @"Success!";
            } else {
                hud.labelText = @"Error";
                hud.detailsLabelText = @"There was an error in sharing the story as an album";
            }
            [hud hide:YES afterDelay:1];
        });
    };
    
    void (^createNewAlbum)(Story *) = ^(Story *story) {
        FBRequestConnection *requestConnection = [[FBRequestConnection alloc] init];
        requestConnection.errorBehavior = FBRequestConnectionErrorBehaviorRetry
        | FBRequestConnectionErrorBehaviorReconnectSession | FBRequestConnectionErrorBehaviorAlertUser;
        
        // Create an album
        NSMutableDictionary<FBOpenGraphObject> *album = [FBGraphObject openGraphObjectForPost];
        album.provisionedForPost = YES;
        album[@"name"] = story.title;
        album[@"message"] = @"";
        FBRequest *albumRequest = [FBRequest requestForPostWithGraphPath:@"me/albums" graphObject:album];
        [requestConnection addRequest:albumRequest completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            completionHandler(error);
        } batchEntryName:@"upload-album"];
        
        __block NSUInteger imageMediaCount = 0;
        for (Piece *piece in story.pieces) {
            Media *media = [Media getMediaOfType:@"image" inMediaSet:piece.media];
            if (media) {
                imageMediaCount++;
                [media getImageForMediaWithSuccess:^(UIImage *image) {
                    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                                image,@"picture",
                                                piece.shortText?:piece.longText?:@"", @"message",
                                                nil];
                    FBRequest *photoRequest = [FBRequest requestWithGraphPath:[NSString stringWithFormat:@"%@/photos", @"{result=upload-album:$.id}"] parameters:parameters HTTPMethod:@"POST"];
                    [requestConnection addRequest:photoRequest completionHandler:nil];
                    imageMediaCount--;
                }
                                          progress:nil
                                           failure:^(NSError *error) {
                                               imageMediaCount--;
                                               BNLogError(@"Error in getting image from media %@ for story %@", media, story.bnObjectId);
                                           }
                 includeThumbnail:NO];
            }
        }
        
        if (!imageMediaCount) {
            [[[UIAlertView alloc] initWithTitle:@"No pictures to upload" message:@"The pieces in this story does not have any pictures to upload" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        do {
            // nothing
        } while (imageMediaCount > 0);
        [requestConnection start];
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performFacebookUserPhotosAction:^(NSError *error){
            if (error) {
                completionHandler(error);
                return;
            }
            [self performFacebookPublishAction:^(NSError *error){
                if (error) {
                    completionHandler(error);
                    return;
                }
                createNewAlbum(self);
            }];
        }];
    });
}

- (void) shareAsLinkOnFacebook
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
    hud.labelText = @"Sharing story";
    hud.detailsLabelText = [NSString stringWithFormat:@"Sharing link to story %@ on Facebook", self.title];
    void (^completionHandler)(NSError *) = ^(NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud setMode:MBProgressHUDModeText];
            if (!error) {
                hud.labelText = @"Success!";
            } else {
                hud.labelText = @"Error";
                hud.detailsLabelText = @"There was an error in sharing a link to the story";
            }
            [hud hide:YES afterDelay:1];
        });
    };
    
    NSArray *contributorsList = self.writeAccess.inviteeList.facebookFriends;
    
    NSMutableArray *fbIds = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *contributor in contributorsList)
    {
        if (![[contributor objectForKey:@"id"] isEqualToString:[BNSharedUser currentUser].facebookId])
            [fbIds addObject:[contributor objectForKey:@"id"]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.media];

        FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:[NSURL URLWithString:self.permaLink]
                                                                       name:self.title caption:self.title description:@"" picture:[NSURL URLWithString:imageMedia.remoteURL]];
        params.dataFailuresFatal = NO;
        params.friends = fbIds;
        params.ref = @"Story";
        if ([FBDialogs canPresentShareDialogWithParams:params]) {
            [FBDialogs presentShareDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                completionHandler(error);
                if (error) {
                    [self showErrorAlert:error];
                }
            }];
        } else {
            if (imageMedia) {
                [imageMedia getImageForMediaWithSuccess:^(UIImage *image) {
                    [self shareOnFacebookWithName:self.title caption:nil description:nil image:image pictureURL:imageMedia.remoteURL.length?imageMedia.remoteURL:nil shareLink:self.permaLink completionHandler:completionHandler];
                }
                                               progress:nil
                                                failure:^(NSError *error) {
                                                    [self shareOnFacebookWithName:self.title caption:nil description:nil image:nil pictureURL:imageMedia.remoteURL.length?imageMedia.remoteURL:nil shareLink:self.permaLink completionHandler:completionHandler];
                                                }
                                       includeThumbnail:NO];
            } else {
                [self shareOnFacebookWithName:self.title caption:nil description:nil image:nil pictureURL:nil shareLink:self.permaLink completionHandler:completionHandler];
            }
        }
    });
}

// Invite selected facebook users to join in the story
- (void)sendInviteRequest
{
    if (!NUMBER_EXISTS(self.bnObjectId)) {
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error" action:@"share" label:@"facebook share without story upload" value:nil];
        return;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:@{@"story": self.bnObjectId,}
                        options:0
                        error:&error];
    if (error) {
        [BNMisc sendGoogleAnalyticsError:error inAction:@"Facebook invites: JSON error" isFatal:NO];
        BNLogError(@"JSON error: %@", error);
        return;
    }
    
    NSString *storyStr = [[NSString alloc]
                          initWithData:jsonData
                          encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary* params = [@{@"data" : storyStr} mutableCopy];
    
    NSMutableArray *idArray = [NSMutableArray array];
    for (NSDictionary *friend in self.readAccess.inviteeList.facebookFriends) {
        [idArray addObject:[friend objectForKey:@"id"]];
    }
    for (NSDictionary *friend in self.writeAccess.inviteeList.facebookFriends) {
        [idArray addObject:[friend objectForKey:@"id"]];
    }
    
    // Filter and only show targeted friends
    if ([idArray count] > 0) {
        NSString *selectIDsStr = [idArray componentsJoinedByString:@","];
        params[@"suggestions"] = selectIDsStr;
    }
    
    // Display the requests dialog
    [FBWebDialogs
     presentRequestsDialogModallyWithSession:nil
     message:[NSString stringWithFormat:@"%@ has invited you to join the story %@", self.author.name, self.title]
     title:@"Invite via Fb!"
     parameters:params
     handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or sending request.
             [BNMisc sendGoogleAnalyticsError:error inAction:@"Facebook invites" isFatal:NO];
             BNLogError(@"Error in facebook invite request to %@.", idArray);
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 BNLogInfo(@"User canceled facebook invite request.");
             } else {
                 // Handle the send request callback
                 NSDictionary *urlParams = [BNMisc parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"request"]) {
                     // User clicked the Cancel button
                     BNLogInfo(@"User canceled facebook invite request.");
                 } else {
                     // User clicked the Send button
                     NSString *requestID = [urlParams valueForKey:@"request"];
                     BNLogInfo(@"Request ID: %@", requestID);
                 }
             }
         }
     }];
}

@end

@implementation Story (UIActionSheetDelegate)
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [BNMisc sendGoogleAnalyticsSocialInteractionWithNetwork:@"Banyan" action:[actionSheet buttonTitleAtIndex:buttonIndex] target:[NSString stringWithFormat:@"Story_%@", self.bnObjectId]];
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:shareAsNewFbAlbumString]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self shareAsAlbumOnFacebook];
        });
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:shareAsLinkOnFacebookString]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self shareAsLinkOnFacebook];
        });
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:copyLinkToStoryString]) {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:REPLACE_NIL_WITH_EMPTY_STRING(self.permaLink)];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = self.permaLink ? @"Link copied" : @"Error copying link";
            if (!self.permaLink) {
                hud.detailsLabelText = @"Make sure the story has been uploaded";
            }
            [hud hide:YES afterDelay:1];
        });
    }
}

@end
