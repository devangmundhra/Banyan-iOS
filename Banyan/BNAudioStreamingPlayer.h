//
//  BNAudioStreamingPlayer.h
//  Banyan
//
//  Created by Devang Mundhra on 5/18/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface BNAudioStreamingPlayer : UIViewController
- (void) loadWithURL:(NSString *)url;
- (IBAction)pause:(id)sender;
- (IBAction)play:(id)sender;
@end
