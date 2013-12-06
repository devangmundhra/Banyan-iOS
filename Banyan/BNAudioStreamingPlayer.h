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
- (void) pause;
@end
