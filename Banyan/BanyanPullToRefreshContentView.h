//
//  BanyanPullToRefreshContentView.h
//  Banyan
//
//  Created by Devang Mundhra on 12/12/12.
//
//

#import <UIKit/UIKit.h>
#import "SSPullToRefreshView.h"
#import <QuartzCore/QuartzCore.h>

@interface BanyanPullToRefreshContentView : UIView <SSPullToRefreshContentView> {
    CALayer *arrowImage;
	CALayer *offlineImage;
}

@property (nonatomic, strong, readonly) UILabel *statusLabel;
@property (nonatomic, strong, readonly) UILabel *lastUpdatedAtLabel;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicatorView;

@end
