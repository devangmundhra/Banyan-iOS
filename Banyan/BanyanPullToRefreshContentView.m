//
//  BanyanPullToRefreshContentView.m
//  Banyan
//
//  Created by Devang Mundhra on 12/12/12.
//
//

#import "BanyanPullToRefreshContentView.h"
#import <math.h>

#define kSSPullToRefreshViewBackgroundColor [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0]
#define kSSPullToRefreshViewTitleColor [UIColor colorWithRed:(87.0/255.0) green:(108.0/255.0) blue:(137.0/255.0) alpha:1.0]
#define kSSPullToRefreshViewLastUpdatedColor kSSPullToRefreshViewTitleColor
#define kSSPullToRefreshViewAnimationDuration 0.18f
#define kSSPullToRefreshViewTriggerOffset -65.0f

@implementation BanyanPullToRefreshContentView

@synthesize statusLabel = _statusLabel;
@synthesize lastUpdatedAtLabel = _lastUpdatedAtLabel;
@synthesize activityIndicatorView = _activityIndicatorView;

#pragma mark - UIView

- (void)showActivity:(BOOL)show animated:(BOOL)animated {
    if (show) [_activityIndicatorView startAnimating];
    else [_activityIndicatorView stopAnimating];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:(animated ? kSSPullToRefreshViewAnimationDuration : 0.0)];
    arrowImage.opacity = (show ? 0.0 : 1.0);
    [UIView commitAnimations];
}

- (void)setImageFlipped:(BOOL)flipped {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kSSPullToRefreshViewAnimationDuration];
    arrowImage.transform = (flipped ? CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f) : CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f));
    [UIView commitAnimations];
}

- (id)initWithFrame:(CGRect)frame {
    
	if ((self = [super initWithFrame:frame])) {        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = kSSPullToRefreshViewBackgroundColor;
        
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 50.0f, frame.size.width, 20.0f)];
		_statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_statusLabel.font = [UIFont boldSystemFontOfSize:14.0f];
		_statusLabel.textColor = kSSPullToRefreshViewTitleColor;
        _statusLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
        _statusLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_statusLabel.backgroundColor = [UIColor clearColor];
		_statusLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:_statusLabel];
        		
        _lastUpdatedAtLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 30.0f, frame.size.width, 20.0f)];
		_lastUpdatedAtLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_lastUpdatedAtLabel.font = [UIFont systemFontOfSize:12.0f];
		_lastUpdatedAtLabel.textColor = kSSPullToRefreshViewLastUpdatedColor;
        _lastUpdatedAtLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		_lastUpdatedAtLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_lastUpdatedAtLabel.backgroundColor = [UIColor clearColor];
		_lastUpdatedAtLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:_lastUpdatedAtLabel];
        
		
        arrowImage = [[CALayer alloc] init];
        arrowImage.frame = CGRectMake(25.0f, frame.size.height - 60.0f, 24.0f, 52.0f);
		arrowImage.contentsGravity = kCAGravityResizeAspect;
        arrowImage.contents = (id) [UIImage imageNamed:@"arrow"].CGImage;
        
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicatorView.frame = CGRectMake(30.0f, frame.size.height - 38.0f, 20.0f, 20.0f);
        [self addSubview:_activityIndicatorView];
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
			arrowImage.contentsScale = [[UIScreen mainScreen] scale];
		}
#endif
        
		[self.layer addSublayer:arrowImage];
	}
	return self;
}


#pragma mark - SSPullToRefreshContentView

- (void)setState:(SSPullToRefreshViewState)state withPullToRefreshView:(SSPullToRefreshView *)view {    
	switch (state) {
		case SSPullToRefreshViewStateReady:
		    self.statusLabel.text = @"Release to refresh…";
            [self showActivity:NO animated:NO];
            [self setImageFlipped:YES];
		    break;
		case SSPullToRefreshViewStateNormal:
		    self.statusLabel.text = @"Pull down to refresh…";
            [self showActivity:NO animated:NO];
            [self setImageFlipped:NO];
		    break;
		case SSPullToRefreshViewStateLoading:
        case SSPullToRefreshViewStateClosing:
		    self.statusLabel.text = @"Loading…";
            [self showActivity:YES animated:YES];
            [self setImageFlipped:NO];
		    break;
		default:
		    break;
	}
    
	[self setNeedsLayout];
}


- (void)setLastUpdatedAt:(NSDate *)date withPullToRefreshView:(SSPullToRefreshView *)view {    
	static NSDateFormatter *dateFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setAMSymbol:@"AM"];
        [dateFormatter setPMSymbol:@"PM"];
        [dateFormatter setDateFormat:@"MM/dd/yy hh:mm a"];
	});
	_lastUpdatedAtLabel.text = [NSString stringWithFormat:@"Last Updated: %@", [dateFormatter stringFromDate:date]];
}

@end
