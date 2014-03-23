//
//  BNAudioRecorder.h
//  Banyan
//
//  Created by Devang Mundhra on 5/18/13.
//
//

#import <UIKit/UIKit.h>
#import "BNAudioRecorderView.h"

@interface BNAudioRecorder : NSObject

- (NSURL *)getRecording;

@end

@interface BNAudioRecorder (BNAudioRecorderViewDelegate) <BNAudioRecorderViewDelegate>

@end