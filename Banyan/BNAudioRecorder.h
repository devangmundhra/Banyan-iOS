//
//  BNAudioRecorder.h
//  Banyan
//
//  Created by Devang Mundhra on 5/18/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface BNAudioRecorder : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, AVAudioSessionDelegate>

- (NSURL *)getRecording;
- (void) loadWithURL:(NSString *)url;

@end
