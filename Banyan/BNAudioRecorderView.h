//
//  BNAudioRecorderView.h
//  Banyan
//
//  Created by Devang Mundhra on 11/12/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class BNAudioRecorderView;

@protocol BNAudioRecorderViewDelegate <NSObject>
- (NSUInteger) bnAudioRecorderAudioRecordDuration;
- (void) bnAudioRecorderViewToRecord:(BNAudioRecorderView *)aRView;
- (void) bnAudioRecorderViewToPlay:(BNAudioRecorderView *)aRView;
- (void) bnAudioRecorderViewToStop:(BNAudioRecorderView *)aRView;
- (void) bnAudioRecorderViewToDelete:(BNAudioRecorderView *)aRView;
@end

@interface BNAudioRecorderView : UIView

@property (weak, nonatomic) IBOutlet id<BNAudioRecorderViewDelegate> delegate;

- (void) setTextForTimeLabel:(NSString *)text;
- (void) refreshUIWithProgress:(NSNumber *)progress;
- (void) setPlayControlButtons;
- (void) setDeleteButton;
@end
