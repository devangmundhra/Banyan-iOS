//
//  Location.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import <Foundation/Foundation.h>


@interface Location : NSObject <NSCoding>

@property (nonatomic, strong) NSNumber * isLocationEnabled;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSString * locationName;

@end
