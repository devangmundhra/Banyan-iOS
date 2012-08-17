//
//  BanyanAppDelegate.h
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "UserManagementModule.h"

#define DEV TRUE

#ifdef DEV
#define PARSE_APP_ID @"5mvyH3aLGv22GeEmYugRZokcrprPevbA4ko1kF6v"
#define PARSE_CLIENT_KEY @"BDbUtm8k0pknUyp3gCeDphUvEWUMLjUY1ksNj02R"
#define PARSE_REST_API_KEY @"UkC05Zb9iA2aPG7a14zFu4wp5YuPH4FzWuLJPKNV"
#define PARSE_MASTER_KEY @"Naq8BwKBUO5W4bBje0h54204QCC4kcFUlEVrsDGA"
#else
#define PARSE_APP_ID @"Q82knolRSmsGKKNK13WCvISIReVVoR3yFP3qTF1J"
#define PARSE_CLIENT_KEY @"mjOegheUYq3rKEJJP2Pr1jhq1cc5ohV9OwDY0w4v"
#define PARSE_REST_API_KEY @"iHiN4Hlw835d7aig6vtcTNhPOkNyJpjpvAL2aSoL"
#define PARSE_MASTER_KEY @"WJij4dz437hs7h9RHQyaIrOMR1CTUYXsIxhYN0nu"
#endif

@interface BanyanAppDelegate : UIResponder <UIApplicationDelegate> {
    UserManagementModule *userManagementModule;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UserManagementModule *userManagementModule;

@end