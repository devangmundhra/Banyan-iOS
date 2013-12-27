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

@implementation Piece (Share)
- (void) shareOnFacebook
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
        } failure:^(NSError *error) {
            [self shareOnFacebookWithName:self.story.title caption:self.shortText description:self.longText image:nil pictureURL:imageMedia.remoteURL.length?imageMedia.remoteURL:nil shareLink:self.permaLink completionHandler:completionHandler];
        }];
    } else {
        [self shareOnFacebookWithName:self.story.title caption:self.shortText description:self.longText image:nil pictureURL:nil shareLink:self.permaLink completionHandler:completionHandler];
    }
}
@end
