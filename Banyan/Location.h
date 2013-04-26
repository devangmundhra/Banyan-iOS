//
//  Location.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import <Foundation/Foundation.h>


@interface Location : NSObject

@property (nonatomic, retain) NSNumber * isLocationEnabled;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * locationName;

@end
