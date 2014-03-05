//
//  BNAudioRecorder.m
//  Banyan
//
//  Created by Devang Mundhra on 5/18/13.
//
//

#import "BNAudioRecorder.h"
#import "BanyanAppDelegate.h"
#import "BNMisc.h"
#import <QuartzCore/QuartzCore.h>

@interface BNAudioRecorder () <AVAudioRecorderDelegate, AVAudioPlayerDelegate, AVAudioSessionDelegate>

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;

@property (strong, nonatomic) NSTimer *timer;

@property (nonatomic) CGFloat currentProgress;
@property (nonatomic) BOOL isRecordingAvailable;

@end

@implementation BNAudioRecorder

#define RECORD_DURATION 15

@synthesize audioPlayer, audioRecorder;
@synthesize timer;
@synthesize currentProgress;
@synthesize isRecordingAvailable;

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self bnAudioRecorderViewToStop:nil];
    NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setActive:NO error: &activationError];
}

- (void)setup
{
    NSURL *docsDir = [BanyanAppDelegate applicationDocumentsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"%@.wav", [BNMisc genRandStringLength:5]];
    NSURL *soundFileURL = [docsDir URLByAppendingPathComponent:fileName];
    
    NSDictionary *recordSettings = [NSDictionary
                                    dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityHigh],
                                    AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16],
                                    AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2],
                                    AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.0],
                                    AVSampleRateKey,
                                    nil];
    
    NSError *error = nil;
    
    audioRecorder = [[AVAudioRecorder alloc]
                     initWithURL:soundFileURL
                     settings:recordSettings
                     error:&error];
    
    if (error) {
        BNLogError(@"error: %@", [error localizedDescription]);
    } else {
        audioRecorder.delegate = self;
    }
    
    currentProgress = 0;
    isRecordingAvailable = NO;
}

#pragma mark timer actions
-(void)timerAction:(NSTimer *)theTimer
{
    NSAssert([timer isValid], @"Time is invalid");
    
    BNAudioRecorderView *aRView = [timer userInfo];

    if (audioRecorder.recording) {
        [aRView setTextForTimeLabel:[NSString stringWithFormat:@"%d/%ds", (int)floor([audioRecorder currentTime]), RECORD_DURATION]];
        currentProgress = [audioRecorder currentTime]/RECORD_DURATION;
    } else if (audioPlayer.playing) {
        [aRView setTextForTimeLabel:[NSString stringWithFormat:@"%d/%ds", (int)floor([audioPlayer currentTime]), (int)floor([audioPlayer duration])]];
        currentProgress = [audioPlayer currentTime]/[audioPlayer duration];
    } else {
        BNLogWarning(@"Neither recording nor playing!!");
    }
    [aRView performSelectorOnMainThread:@selector(refreshUIWithProgress:) withObject:[NSNumber numberWithFloat:currentProgress] waitUntilDone:YES];
}

- (void)invalidateTimer
{
    NSAssert([timer isValid], @"Time is invalid");
    
    BNAudioRecorderView *aRView = [timer userInfo];
    
    if ([timer isValid])
        [timer invalidate];
    timer = nil;
    currentProgress = 0;
    [aRView performSelectorOnMainThread:@selector(refreshUIWithProgress:) withObject:[NSNumber numberWithFloat:currentProgress] waitUntilDone:YES];
}

#pragma mark AudioPlayer/Recorder Delegate Methods
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSAssert([timer isValid], @"Time is invalid_1");
    BNAudioRecorderView *aRView = [timer userInfo];
    
    [self performSelectorOnMainThread:@selector(invalidateTimer) withObject:nil waitUntilDone:YES];
    [aRView setPlayControlButtons];
    [aRView setTextForTimeLabel:[NSString stringWithFormat:@"0/%ds", (int)floor([player duration])]];
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:NO error: &activationError];
    player = nil; // Make this nil to release player memory
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player
                                error:(NSError *)error
{
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:NO error: &activationError];
    BNLogError(@"Decode Error occurred");
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags
{
    
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder
                          successfully:(BOOL)flag
{
    NSAssert([timer isValid], @"Time is invalid_2");
    BNAudioRecorderView *aRView = [timer userInfo];
    
    [self performSelectorOnMainThread:@selector(invalidateTimer) withObject:nil waitUntilDone:YES];
    [aRView setPlayControlButtons];
    [aRView setDeleteButton];
    isRecordingAvailable = YES;
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:NO error: &activationError];
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder
                                  error:(NSError *)error
{
    BNLogError(@"Encode Error occurred");
}

#pragma mark instance methods
- (NSURL *)getRecording
{
    if (isRecordingAvailable)
        return audioRecorder.url;
    
    return nil;
}

@end

@implementation BNAudioRecorder (BNAudioRecorderViewDelegate)

- (NSUInteger) bnAudioRecorderAudioRecordDuration
{
    return RECORD_DURATION;
}

- (void) bnAudioRecorderViewToRecord:(BNAudioRecorderView *)aRView
{
    if (!audioRecorder.recording) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
        // Activates the audio session.
        NSError *activationError = nil;
        [[AVAudioSession sharedInstance] setActive:YES error: &activationError];
        
        [audioRecorder recordForDuration:RECORD_DURATION+0.7]; // record for upto RECORD_DURATION seconds
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:aRView repeats:YES];
        // The RunLoop will be the Main thread runloop since this is called in response to user event
    }
}

- (void)bnAudioRecorderViewToPlay:(BNAudioRecorderView *)aRView
{
    if (!audioRecorder.recording)
    {
        NSError *error = nil;
        
        audioPlayer = [[AVAudioPlayer alloc]
                       initWithContentsOfURL:audioRecorder.url
                       error:&error];
        
        if (error) {
            BNLogError(@"Error: %@",
                  [error localizedDescription]);
        }
        else {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            // Activates the audio session.
            NSError *activationError = nil;
            [[AVAudioSession sharedInstance] setActive:YES error: &activationError];
            audioPlayer.delegate = self;
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:aRView repeats:YES];
            // The RunLoop will be the Main thread runloop since this is called in response to user event
            [audioPlayer play];
        }
    }
}

- (void) bnAudioRecorderViewToStop:(BNAudioRecorderView *)aRView
{
    if (audioRecorder.recording) {
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
        [self invalidateTimer];
    }
}

- (void) bnAudioRecorderViewToDelete:(BNAudioRecorderView *)aRView
{
    if (audioPlayer.playing) {
        [audioPlayer stop];
        [self invalidateTimer];
    }
    [audioRecorder deleteRecording];
    isRecordingAvailable = NO;
}

@end