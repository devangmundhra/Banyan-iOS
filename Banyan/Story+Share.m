//
//  Story+Share.m
//  Banyan
//
//  Created by Devang Mundhra on 12/26/13.
//
//

#import "Story+Share.h"
#import "Media.h"
#import "User.h"
#import "Piece.h"

@interface Story (UIActionSheetDelegate) <UIActionSheetDelegate>
@end

@implementation Story (Share)

- (void) shareOnFacebook
{
    UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:@"How would you like to share this story" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Share as a link on Facebook", @"Share as a new album on Facebook", @"Copy link to story", nil];
    
    [shareSheet showInView:APP_DELEGATE.topMostController.view];
    
    [BNMisc sendGoogleAnalyticsSocialInteractionWithNetwork:@"Banyan" action:@"share" target:[NSString stringWithFormat:@"Story_%@", self.bnObjectId]];
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    createNewAlbum(self);
                });
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
    
    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
    params.dataFailuresFatal = NO;
    params.caption = self.title;
    params.description = @"";
    params.friends = fbIds;
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.media];
    params.picture = [NSURL URLWithString:imageMedia.remoteURL];
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
}

@end

@implementation Story (UIActionSheetDelegate)
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share as a new album on Facebook"]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self shareAsAlbumOnFacebook];
        });
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share as a link on Facebook"]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self shareAsLinkOnFacebook];
        });
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copy link to story"]) {
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
