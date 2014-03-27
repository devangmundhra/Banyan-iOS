//
//  Piece+Share.m
//  Banyan
//
//  Created by Devang Mundhra on 12/26/13.
//
//

#import "Piece+Share.h"
#import "Media+Transfer.h"
#import "Story.h"

NSString *const shareAsAPicOnFbString = @"Share as a picture on Facebook";
NSString *const copyLinkToPieceString = @"Copy link to piece";

@interface Piece (UIActionSheetDelegate) <UIActionSheetDelegate>
@end

@implementation Piece (Share)

- (void) shareOnFacebook
{
    UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:@"How would you like to share this piece" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:shareAsAPicOnFbString, copyLinkToPieceString, nil];
    
    [shareSheet showInView:APP_DELEGATE.topMostController.view];
}


- (void) shareAsPictureOnFacebook
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
    hud.labelText = @"Sharing piece";
    hud.detailsLabelText = @"Sharing this piece on Facebook";
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
}
@end

@implementation Piece (UIActionSheetDelegate)
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [BNMisc sendGoogleAnalyticsSocialInteractionWithNetwork:@"Banyan" action:[actionSheet buttonTitleAtIndex:buttonIndex]
                                                     target:[NSString stringWithFormat:@"Piece_%@", self.bnObjectId]];
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:shareAsAPicOnFbString]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self shareAsPictureOnFacebook];
        });
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:copyLinkToPieceString]) {
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