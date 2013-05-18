//
//  BNAudioStreamingPlayer.m
//  Banyan
//
//  Created by Devang Mundhra on 5/18/13.
//
//

#import "BNAudioStreamingPlayer.h"

static void *BNAudioStreamingPlayerViewRateObservationContext = &BNAudioStreamingPlayerViewRateObservationContext;
static void *BNAudioStreamingPlayerViewCurrentItemObservationContext = &BNAudioStreamingPlayerViewCurrentItemObservationContext;
static void *BNAudioStreamingPlayerViewPlayerItemStatusObserverContext = &BNAudioStreamingPlayerViewPlayerItemStatusObserverContext;

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";

#pragma mark -
@interface BNAudioStreamingPlayer (Player)
- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
- (void)assetFailedToPrepareForPlayback:(NSError *)error;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
@end

@interface BNAudioStreamingPlayer ()

@property (strong, nonatomic) UIToolbar *toolBar;
@property (strong, nonatomic) UISlider *audioTimeControl;
@property (strong, nonatomic) UIBarButtonItem *playButton;
@property (strong, nonatomic) UIBarButtonItem *stopButton;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;

@property (nonatomic) BOOL isSeeking;
@property (nonatomic) BOOL seekToZeroBeforePlay;
@property (nonatomic) float restoreAfterScrubbingRate;

@property (nonatomic, strong) id timeObserver;

@end

@implementation BNAudioStreamingPlayer

@synthesize toolBar, audioTimeControl;
@synthesize playButton, stopButton;
@synthesize player, playerItem;
@synthesize isSeeking, seekToZeroBeforePlay, restoreAfterScrubbingRate, timeObserver;

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
    CGRect bounds = self.view.bounds;
    toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), 44)];
    toolBar.tintColor = BANYAN_GREEN_COLOR;
    toolBar.translucent = YES;
    toolBar.backgroundColor = BANYAN_BLACK_COLOR;
    [self.view addSubview:toolBar];
    
    audioTimeControl = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), 44)];
    CGRect frame = audioTimeControl.frame;
    CGPoint center = audioTimeControl.center;
    frame.size.width = 266;
    frame.size.height = 22;
    audioTimeControl.frame = frame;
    audioTimeControl.center = center;
    
    [audioTimeControl addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [audioTimeControl addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventTouchDragInside];
    [audioTimeControl addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [audioTimeControl addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    [audioTimeControl addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    
    playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play:)];
    stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pause:)];
    
    UIBarButtonItem *scrubberItem = [[UIBarButtonItem alloc] initWithCustomView:audioTimeControl];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    toolBar.items = [NSArray arrayWithObjects:playButton, flexItem, scrubberItem, nil];
}

- (void) loadWithURL:(NSString *)urlString
{
    if (urlString.length > 0)
	{
		NSURL *newAudioURL = [NSURL URLWithString:urlString];
		if ([newAudioURL scheme])	/* Sanity check on the URL. */
		{
			/*
			 Create an asset for inspection of a resource referenced by a given URL.
			 Load the values for the asset keys "tracks", "playable".
			 */
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:newAudioURL options:nil];
            
			NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
			
			/* Tells the asset to load the values of any of the specified keys that are not already loaded. */
			[asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
			 ^{
				 dispatch_async( dispatch_get_main_queue(),
								^{
									/* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
									[self prepareToPlayAsset:asset withKeys:requestedKeys];
								});
			 }];
		}
	}
}
#pragma mark -
#pragma mark Movie controller methods
#pragma mark -

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

#pragma mark Play, Stop Buttons

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[toolBar items]];
    [toolbarItems replaceObjectAtIndex:0 withObject:stopButton];
    toolBar.items = toolbarItems;
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[toolBar items]];
    [toolbarItems replaceObjectAtIndex:0 withObject:playButton];
    toolBar.items = toolbarItems;
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
	if ([self isPlaying])
	{
        [self showStopButton];
	}
	else
	{
        [self showPlayButton];
	}
}

-(void)enablePlayerButtons
{
    self.playButton.enabled = YES;
    self.stopButton.enabled = YES;
}

-(void)disablePlayerButtons
{
    self.playButton.enabled = NO;
    self.stopButton.enabled = NO;
}

#pragma mark Scrubber control

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		audioTimeControl.minimumValue = 0.0;
		return;
	}
	
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration) && (duration > 0))
	{
		float minValue = [audioTimeControl minimumValue];
		float maxValue = [audioTimeControl maximumValue];
		double time = CMTimeGetSeconds([player currentTime]);
		[audioTimeControl setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

/* Requests invocation of a given block during media playback to update the
 movie scrubber control. */
-(void)initScrubberTimer
{
	double interval = .1f;
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		return;
	}
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([audioTimeControl bounds]);
		interval = 0.5f * duration / width;
	}
    
	/* Update the scrubber during normal playback. */
    __weak BNAudioStreamingPlayer *weakSelf = self;
    
	timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                        queue:NULL
                                                   usingBlock:
                    ^(CMTime time)
                    {
                        [weakSelf syncScrubber];
                    }];
}

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
	if (timeObserver)
	{
		[player removeTimeObserver:timeObserver];
		timeObserver = nil;
	}
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender
{
	restoreAfterScrubbingRate = [player rate];
	[player setRate:0.f];
	
	/* Remove previous timer. */
	[self removePlayerTimeObserver];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender
{
	if (!timeObserver)
	{
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration))
		{
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([audioTimeControl bounds]);
			double tolerance = 0.5f * duration / width;
            
            __weak BNAudioStreamingPlayer *weakSelf = self;
			timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
                            ^(CMTime time)
                            {
                                [weakSelf syncScrubber];
                            }];
		}
	}
    
	if (restoreAfterScrubbingRate)
	{
		[player setRate:restoreAfterScrubbingRate];
		restoreAfterScrubbingRate = 0.f;
	}
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
	if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			double time = duration * (value - minValue) / (maxValue - minValue);
			
			[player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
		}
	}
}

- (BOOL)isScrubbing
{
	return restoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    self.audioTimeControl.enabled = YES;
}

-(void)disableScrubber
{
    self.audioTimeControl.enabled = NO;
}

/* Prevent the slider from seeking during Ad playback. */
- (void)sliderSyncToPlayerSeekableTimeRanges
{
	NSArray *seekableTimeRanges = [[player currentItem] seekableTimeRanges];
	if ([seekableTimeRanges count] > 0)
	{
		NSValue *range = [seekableTimeRanges objectAtIndex:0];
		CMTimeRange timeRange = [range CMTimeRangeValue];
		float startSeconds = CMTimeGetSeconds(timeRange.start);
		float durationSeconds = CMTimeGetSeconds(timeRange.duration);
		
		/* Set the minimum and maximum values of the time slider to match the seekable time range. */
		audioTimeControl.minimumValue = startSeconds;
		audioTimeControl.maximumValue = startSeconds + durationSeconds;
	}
}


#pragma mark Button Action Methods
- (IBAction)play:(id)sender
{
	/* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
	if (seekToZeroBeforePlay == YES)
	{
		seekToZeroBeforePlay = NO;
		[player seekToTime:kCMTimeZero];
	}
    
	[player play];
	
    [self showStopButton];
}

- (IBAction)pause:(id)sender
{
	[player pause];
    
    [self showPlayButton];
}

@end

@implementation BNAudioStreamingPlayer (Player)

#pragma mark -

#pragma mark Player

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem.
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
	AVPlayerItem *thePlayerItem = [player currentItem];
	if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
	{
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
		return([playerItem duration]);
	}
    
	return(kCMTimeInvalid);
}

- (BOOL)isPlaying
{
	return restoreAfterScrubbingRate != 0.f || [player rate] != 0.f;
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification
{
	/* Hide the 'Pause' button, show the 'Play' button in the slider control */
    [self showPlayButton];
    
	/* After the movie has played to its end time, seek back to time zero
     to play it again */
	seekToZeroBeforePlay = YES;
}



#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}

#pragma mark Prepare to play asset

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		/* If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail
         out properly in the case of cancellation. */
	}
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey,
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	/* At this point we're ready to set up for playback of the asset. */
    
	[self initScrubberTimer];
	[self enableScrubber];
	[self enablePlayerButtons];
	
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
	
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BNAudioStreamingPlayerViewPlayerItemStatusObserverContext];
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
	
    seekToZeroBeforePlay = NO;
	
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
		
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BNAudioStreamingPlayerViewCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BNAudioStreamingPlayerViewRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
	
    [audioTimeControl setValue:0.0];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
	/* AVPlayerItem "status" property value observer. */
	if (context == BNAudioStreamingPlayerViewPlayerItemStatusObserverContext)
	{
		[self syncPlayPauseButtons];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self disableScrubber];
                [self disablePlayerButtons];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [toolBar setHidden:NO];
                
                /* Show the movie slider control since the movie is now ready to play. */
                audioTimeControl.hidden = NO;
                
                [self enableScrubber];
                [self enablePlayerButtons];
                
                [self initScrubberTimer];
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
                break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == BNAudioStreamingPlayerViewRateObservationContext)
	{
        [self syncPlayPauseButtons];
	}
	/* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
	else if (context == BNAudioStreamingPlayerViewCurrentItemObservationContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* New player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
        }
        else /* Replacement of player currentItem has occurred */
        {
            [self syncPlayPauseButtons];
        }
	}
	else
	{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
    
    return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
