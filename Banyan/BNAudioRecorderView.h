//
//  BNAudioManagerView.h
//  Banyan
//
//  Created by Devang Mundhra on 5/13/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface BNAudioRecorderView : UIView <AVAudioRecorderDelegate, AVAudioPlayerDelegate, AVAudioSessionDelegate>

- (NSURL *)getRecording;
- (void) loadWithURL:(NSString *)url;

@end
