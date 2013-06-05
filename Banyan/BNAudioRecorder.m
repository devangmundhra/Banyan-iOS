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

@interface BNAudioRecorder ()
@property (strong, nonatomic) IBOutlet UIButton *controlButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UISlider *slider;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) UIImageView *progressBar;
@property (strong, nonatomic) UIImageView *sliderBar;

@property (nonatomic) CGFloat currentProgress;
@end

@implementation BNAudioRecorder

#define RECORD_DURATION 15

@synthesize controlButton, deleteButton;
@synthesize audioPlayer, audioRecorder;
@synthesize timeLabel, timer;
@synthesize progressBar, sliderBar;
@synthesize currentProgress;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self setup];
}

- (void)setup
{
    NSString *docsDir = [BanyanAppDelegate applicationDocumentsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"%@.caf", [BNMisc genRandStringLength:5]];
    NSString *soundFilePath = [docsDir
                               stringByAppendingPathComponent:fileName];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    
    NSDictionary *recordSettings = [NSDictionary
                                    dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityMax],
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
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [audioRecorder prepareToRecord];
        audioRecorder.delegate = self;
    }
    
    self.view.backgroundColor = BANYAN_BROWN_COLOR;
    
    controlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [controlButton setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [controlButton addTarget:self action:@selector(recordAudio:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:controlButton];
    
    deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [deleteButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteRecording:) forControlEvents:UIControlEventTouchUpInside];
    deleteButton.enabled = NO; deleteButton.hidden = YES;
    [self.view addSubview:deleteButton];
    
    timeLabel = [[UILabel alloc] init];
    timeLabel.text = [NSString stringWithFormat:@"0/%ds", RECORD_DURATION];
    timeLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
    timeLabel.textColor = BANYAN_WHITE_COLOR;
    timeLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:timeLabel];
    
    sliderBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"emptyBar"]
                                                    resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]];
    sliderBar.backgroundColor = [UIColor clearColor];
    [sliderBar.layer setCornerRadius:4.0f];
    [sliderBar.layer setMasksToBounds:YES];
    [self.view addSubview:sliderBar];
    progressBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"progressBar"]
                                                      resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]];
    progressBar.backgroundColor = [UIColor clearColor];
    [progressBar.layer setCornerRadius:4.0f];
    [progressBar.layer setMasksToBounds:YES];
    
    currentProgress = 0;
    [self.view addSubview:progressBar];    
}

- (void)refreshUI
{
    CGRect bounds = self.view.bounds;
    controlButton.frame = CGRectMake(0, 0, 40, CGRectGetHeight(bounds));
    
    sliderBar.frame = CGRectMake(40, 0, CGRectGetWidth(bounds)-125, 11);
    progressBar.frame = CGRectMake(40, 0, (CGRectGetWidth(bounds)-125)*currentProgress, 11);
    // Correct the y-position for the bar
    CGPoint center = sliderBar.center;
    center.y = CGRectGetMidY(bounds);
    sliderBar.center = center;
    
    center = progressBar.center;
    center.y = CGRectGetMidY(bounds);
    progressBar.center = center;
    
    timeLabel.frame = CGRectMake(CGRectGetMaxX(sliderBar.frame)+5, 0, 40, CGRectGetHeight(bounds));
    deleteButton.frame = CGRectMake(CGRectGetMaxX(timeLabel.frame), 0, 40, CGRectGetHeight(bounds));
}

#pragma mark target actions
- (IBAction) recordAudio:(id)sender
{
    assert([NSThread isMainThread]);
    
    if (!audioRecorder.recording)
    {
        [controlButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        [controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [controlButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
        [audioRecorder recordForDuration:RECORD_DURATION+0.7]; // record for upto 20 seconds
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
        // The RunLoop will be the Main thread runloop since this is called in response to user event
    }
}

- (IBAction) playAudio:(id)sender
{
    assert([NSThread isMainThread]);
    
    if (!audioRecorder.recording)
    {
        NSError *error = nil;
        
        audioPlayer = [[AVAudioPlayer alloc]
                       initWithContentsOfURL:audioRecorder.url
                       error:&error];
        
        if (error) {
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        }
        else {
            audioPlayer.delegate = self;
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
            // The RunLoop will be the Main thread runloop since this is called in response to user event
            [audioPlayer play];
        }
    }
    [controlButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    [controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [controlButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction) stop:(id)sender
{
    assert([NSThread isMainThread]);
    
    if (audioRecorder.recording) {
        timeLabel.text = [NSString stringWithFormat:@"0/%ds", (int)floor([audioRecorder currentTime])];
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }
    [self invalidateTimer];
    [controlButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [controlButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)deleteRecording:(id)sender
{
    if (audioPlayer.playing) {
        [audioPlayer stop];
        [self invalidateTimer];
    }
    [audioRecorder deleteRecording];
    deleteButton.enabled = NO; deleteButton.hidden = YES;
    [controlButton setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [controlButton addTarget:self action:@selector(recordAudio:) forControlEvents:UIControlEventTouchUpInside];
    timeLabel.text = [NSString stringWithFormat:@"0/%ds", RECORD_DURATION];
}

#pragma mark timer actions
-(void)timerAction:(NSTimer *)theTimer
{
    if (audioRecorder.recording) {
        timeLabel.text = [NSString stringWithFormat:@"%d/%ds", (int)floor([audioRecorder currentTime]), RECORD_DURATION];
        currentProgress = [audioRecorder currentTime]/RECORD_DURATION;
    } else if (audioPlayer.playing) {
        timeLabel.text = [NSString stringWithFormat:@"%d/%ds", (int)floor([audioPlayer currentTime]), (int)floor([audioPlayer duration])];
        currentProgress = [audioPlayer currentTime]/[audioPlayer duration];
    } else {
        NSLog(@"ERROR %s Neither recording nor playing!!", __PRETTY_FUNCTION__);
        assert(false);
    }
    [self performSelectorInBackground:@selector(refreshUI) withObject:nil];
}

- (void)invalidateTimer
{
    if ([timer isValid])
        [timer invalidate];
    timer = nil;
    currentProgress = 0;
    [self performSelectorInBackground:@selector(refreshUI) withObject:nil];
}

#pragma mark AudioPlayer/Recorder Delegate Methods
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self performSelectorOnMainThread:@selector(invalidateTimer) withObject:nil waitUntilDone:YES];
    [controlButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [controlButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
    timeLabel.text = [NSString stringWithFormat:@"0/%ds", (int)floor([player duration])];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player
                                error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder
                          successfully:(BOOL)flag
{
    [self performSelectorOnMainThread:@selector(invalidateTimer) withObject:nil waitUntilDone:YES];
    [controlButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [controlButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
    deleteButton.enabled = YES; deleteButton.hidden = NO;
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder
                                  error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}

#pragma mark instance methods
- (NSURL *)getRecording
{
    if (deleteButton.isEnabled) {
        // There is a recording. Return it.
        return audioRecorder.url;
    }
    return nil;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:self];
    [self refreshUI];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
