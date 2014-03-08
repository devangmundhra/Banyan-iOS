//
//  Piece+Share.m
//  Banyan
//
//  Created by Devang Mundhra on 12/26/13.
//
//

#import "Piece+Share.h"
#import "Media.h"
#import "Story.h"

@interface Piece (UIActionSheetDelegate) <UIActionSheetDelegate>
@end

@implementation Piece (Share)

- (void) shareOnFacebook
{
    UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:@"How would you like to share this piece" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Share as a picture on facebook", @"Copy link to piece", nil];
    
    [shareSheet showInView:APP_DELEGATE.topMostController.view];
}


- (void) shareAsPictureOnFacebook
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
    hud.labelText = @"Sharing piece";
    hud.detailsLabelText = @"Sharing link to this piece on Facebook";
    void (^completionHandler)(NSError *) = ^(NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud setMode:MBProgressHUDModeText];
            if (!error) {
                hud.labelText = @"Success!";
            } else {
                hud.labelText = @"Error";
                hud.detailsLabelText = @"There was an error in sharing a link to the piece";
            }
            [hud hide:YES afterDelay:1];
        });
    };
    
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.media];
    
    if (imageMedia) {
        [imageMedia getImageForMediaWithSuccess:^(UIImage *image) {
            [self shareOnFacebookWithName:self.story.title caption:self.shortText description:self.longText image:image pictureURL:imageMedia.remoteURL.length?imageMedia.remoteURL:nil shareLink:self.permaLink completionHandler:completionHandler];
        } progress:nil failure:^(NSError *error) {
            [self shareOnFacebookWithName:self.story.title caption:self.shortText description:self.longText image:nil pictureURL:imageMedia.remoteURL.length?imageMedia.remoteURL:nil shareLink:self.permaLink completionHandler:completionHandler];
        }
         includeThumbnail:NO];
    } else {
        [self shareOnFacebookWithName:self.story.title caption:self.shortText description:self.longText image:nil pictureURL:nil shareLink:self.permaLink completionHandler:completionHandler];
    }
}
@end

@implementation Piece (UIActionSheetDelegate)
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [BNMisc sendGoogleAnalyticsSocialInteractionWithNetwork:@"Banyan" action:[actionSheet buttonTitleAtIndex:buttonIndex]
                                                     target:[NSString stringWithFormat:@"Piece_%@", self.bnObjectId]];
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Share as a picture on facebook"]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self shareAsPictureOnFacebook];
        });
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copy link to piece"]) {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:REPLACE_NIL_WITH_EMPTY_STRING(self.permaLink)];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = self.permaLink ? @"Link copied" : @"Error copying link";
            if (!self.permaLink) {
                hud.detailsLabelText = @"Make sure the piece has been uploaded";
            }
            [hud hide:YES afterDelay:1];
        });
    }
}

@end