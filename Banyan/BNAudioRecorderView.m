//
//  BNAudioRecorderView.m
//  Banyan
//
//  Created by Devang Mundhra on 11/12/13.
//
//

#import "BNAudioRecorderView.h"

@interface BNAudioRecorderView ()
@property (strong, nonatomic) IBOutlet UIButton *controlButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UISlider *slider;

@property (strong, nonatomic) UIImageView *progressBar;
@property (strong, nonatomic) UIImageView *sliderBar;


@end

@implementation BNAudioRecorderView

@synthesize delegate = _delegate;
@synthesize controlButton = _controlButton;
@synthesize deleteButton = _deleteButton;
@synthesize timeLabel = _timeLabel;
@synthesize progressBar = _progressBar;
@synthesize sliderBar = _sliderBar;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self stop:nil];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    CGFloat white = 1;
    CGFloat alpha = 1;
    [backgroundColor getWhite:&white alpha:&alpha];
    
    [super setBackgroundColor:backgroundColor];
    [self.controlButton setBackgroundColor:[self.controlButton.backgroundColor colorWithAlphaComponent:alpha]];
    [self.slider setBackgroundColor:[self.slider.backgroundColor colorWithAlphaComponent:alpha]];
    [self.progressBar setBackgroundColor:[self.progressBar.backgroundColor colorWithAlphaComponent:alpha]];
}

- (void) setDelegate:(id<BNAudioRecorderViewDelegate>)delegate
{
    _delegate = delegate;
    [self setTextForTimeLabel:[NSString stringWithFormat:@"0/%ds", [delegate bnAudioRecorderAudioRecordDuration]]];
}

- (void) setup
{    
    _controlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_controlButton setImage:[UIImage imageNamed:@"Microphone"] forState:UIControlStateNormal];
    [_controlButton addTarget:self action:@selector(recordAudio:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_controlButton];
    
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_deleteButton setImage:[UIImage imageNamed:@"Trash"] forState:UIControlStateNormal];
    [_deleteButton addTarget:self action:@selector(deleteRecording:) forControlEvents:UIControlEventTouchUpInside];
    _deleteButton.enabled = NO; _deleteButton.hidden = YES;
    [self addSubview:_deleteButton];
    
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.text = [NSString stringWithFormat:@"0/%ds", self.delegate.bnAudioRecorderAudioRecordDuration];
    _timeLabel.font = [UIFont fontWithName:@"Roboto-Condensed" size:14];
    _timeLabel.textColor = BANYAN_WHITE_COLOR;
    _timeLabel.backgroundColor = BANYAN_CLEAR_COLOR;
    [self addSubview:_timeLabel];
    
    _sliderBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"emptyBar"]
                                                    resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]];
    _sliderBar.backgroundColor = BANYAN_BROWN_COLOR;
    [_sliderBar.layer setCornerRadius:4.0f];
    [_sliderBar.layer setMasksToBounds:YES];
    [self addSubview:_sliderBar];

    _progressBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"progressBar"]
                                                      resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]];
    _progressBar.backgroundColor = BANYAN_BROWN_COLOR;
    [_progressBar.layer setCornerRadius:4.0f];
    [_progressBar.layer setMasksToBounds:YES];
    [self addSubview:_progressBar];
    
    [self refreshUIWithProgress:[NSNumber numberWithFloat:0]];
}

- (void)refreshUIWithProgress:(NSNumber *)progress
{
    CGRect bounds = self.bounds;
    self.controlButton.frame = CGRectMake(0, 0, 40, CGRectGetHeight(bounds));
    
    self.sliderBar.frame = CGRectMake(40, 0, CGRectGetWidth(bounds)-125, 11);
    self.progressBar.frame = CGRectMake(40, 0, (CGRectGetWidth(bounds)-125)*[progress floatValue], 11);
    // Correct the y-position for the bar
    CGPoint center = self.sliderBar.center;
    center.y = CGRectGetMidY(bounds);
    self.sliderBar.center = center;
    
    center = self.progressBar.center;
    center.y = CGRectGetMidY(bounds);
    self.progressBar.center = center;
    
    self.timeLabel.frame = CGRectMake(CGRectGetMaxX(self.sliderBar.frame)+5, 0, 50, CGRectGetHeight(bounds));
    self.deleteButton.frame = CGRectMake(CGRectGetMaxX(self.timeLabel.frame), 0, 25, CGRectGetHeight(bounds));
    [self setNeedsDisplay];
}

- (void) setTextForTimeLabel:(NSString *)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timeLabel.text = text;
    });
}

#pragma mark target actions
- (IBAction) recordAudio:(id)sender
{
    [self.controlButton setImage:[UIImage imageNamed:@"Stop"] forState:UIControlStateNormal];
    [self.controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.controlButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
    [self.delegate bnAudioRecorderViewToRecord:self];
}

- (IBAction) playAudio:(id)sender
{
    [self.delegate bnAudioRecorderViewToPlay:self];
    [self.controlButton setImage:[UIImage imageNamed:@"Stop"] forState:UIControlStateNormal];
    [self.controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.controlButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction) stop:(id)sender
{
    [self.delegate bnAudioRecorderViewToStop:self];
    [self.controlButton setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    [self.controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.controlButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)deleteRecording:(id)sender
{
    [self.delegate bnAudioRecorderViewToDelete:self];
    self.deleteButton.enabled = NO; self.deleteButton.hidden = YES;
    [self.controlButton setImage:[UIImage imageNamed:@"Microphone"] forState:UIControlStateNormal];
    [self.controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.controlButton addTarget:self action:@selector(recordAudio:) forControlEvents:UIControlEventTouchUpInside];
    self.timeLabel.text = [NSString stringWithFormat:@"0/%ds", [self.delegate bnAudioRecorderAudioRecordDuration]];
}

- (void)setPlayControlButtons
{
    [self.controlButton setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    [self.controlButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.controlButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setDeleteButton
{
    self.deleteButton.enabled = YES; self.deleteButton.hidden = NO;
}

@end
