//
//  LocationManager.h
//  Banyan
//
//  Created by Devang Mundhra on 8/7/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol LocationManagerDelegate <NSObject>

- (void) newStoryViewController:(NewStoryViewController *) sender didAddStory:(Story *)story;

@end

@interface LocationManager : NSObject <CLLocationManagerDelegate>

@end
