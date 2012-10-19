//
//  BanyanAppDelegate.m
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BanyanAppDelegate.h"
#import "User_Defines.h"
#import "AFParseAPIClient.h"
#import "StoryListTableViewController.h"

@implementation BanyanAppDelegate

@synthesize window = _window;
@synthesize userManagementModule;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:PARSE_APP_ID
                  clientKey:PARSE_CLIENT_KEY];
    
    // Override point for customization after application launch.
    [PFFacebookUtils initializeWithApplicationId:FACEBOOK_APP_ID];
    
#define TESTING 1
#ifdef TESTING
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"UUID"]) {
        [TestFlight setDeviceIdentifier:[defaults objectForKey:@"UUID"]];
    } else {
        //        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        //        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        //        CFRelease(theUUID);
        //        NSString *uuidString = (__bridge_transfer NSString *)string;
        NSString *uuidString = [[UIDevice currentDevice] uniqueIdentifier];
        [defaults setObject:uuidString forKey:@"UUID"];
        [defaults synchronize];
        [TestFlight setDeviceIdentifier:uuidString];
    }
#endif
    
    [TestFlight takeOff:TESTFLIGHT_BANYAN_TEAM_TOKEN];
    
    // Create a location manager instance to determine if location services are enabled. This manager instance will be
    // immediately released afterwards.
    if ([CLLocationManager locationServicesEnabled] == NO) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        [TestFlight passCheckpoint:@"AppDelegate All location services disabled alert"];
    }
    
    [self appearances];
    
    userManagementModule = [[UserManagementModule alloc] init];
    
    if ([User loggedIn]) {
        // User has Facebook ID.
        // Update user details and get updates on FB friends
        [PF_FBRequestConnection startForMeWithCompletionHandler:^(PF_FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self facebookRequest:connection didLoad:result];
            } else {
                [self facebookRequest:connection didFailWithError:error];
            }
        }];
    } else {
        NSLog(@"User missing Facebook ID");
    }
    
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert];
    
    return YES;
}

#pragma mark customize appearnaces
- (void) appearances
{
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:136/255.0 green:103/255.0 blue:68/255.0 alpha:1]];
    
    [[UIToolbar appearance] setTintColor:[UIColor colorWithRed:136/255.0 green:103/255.0 blue:68/255.0 alpha:1]];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:44/255.0 green:127/255.0 blue:84/255.0 alpha:1]];
    
    [[UISwitch appearance] setOnTintColor:[UIColor colorWithRed:44/255.0 green:127/255.0 blue:84/255.0 alpha:1]];
    
    [[UISegmentedControl appearance] setTintColor:[UIColor colorWithRed:136/255.0 green:103/255.0 blue:68/255.0 alpha:1]];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    [[UISlider appearance] setThumbTintColor:[UIColor colorWithRed:44/255.0 green:127/255.0 blue:84/255.0 alpha:1]];
    [[UISlider appearance] setMinimumTrackTintColor:[UIColor colorWithRed:136/255.0 green:103/255.0 blue:68/255.0 alpha:1]];
}

#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}

#pragma mark application methods

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // We need to properly handle activation of the application with regards to SSO
    // (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [PF_FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [PF_FBSession.activeSession close];
    [self setUserManagementModule:nil];
}

# pragma mark push notifications
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    // Tell Parse about the device token.
    [PFPush storeDeviceToken:newDeviceToken];
    // Subscribe to the global broadcast channel.
    [PFPush subscribeToChannelInBackground:@""];
}

- (void)application:(UIApplication *)application 
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)facebookRequest:(PF_FBRequestConnection *)connection didLoad:(id)result
{
    // This method is called twice - once for the user's /me profile, and a second time when obtaining their friends. We will try and handle both scenarios in a single method.
    
    NSArray *data = [result objectForKey:@"data"];
    
    if (data) {
        // we have friends data
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:data forKey:BNUserDefaultsFacebookFriends];
        [defaults synchronize];
        
        // Get friends being followed
        NSMutableArray *facebookFriendsId = [NSMutableArray array];
        for (NSDictionary *facebookFriend in [defaults objectForKey:BNUserDefaultsFacebookFriends]) {
            [facebookFriendsId addObject:[facebookFriend objectForKey:@"id"]];
        }
        
        [[AFParseAPIClient sharedClient] postPath:PARSE_API_FUNCTION_URL(@"facebookFriendsOnBanyan")
                                       parameters:[NSDictionary dictionaryWithObject:facebookFriendsId forKey:@"facebookFriendsId"]
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             NSDictionary *results = (NSDictionary *)responseObject;
                                             NSArray *friendsOnBanyan = [results objectForKey:@"result"];
                                             NSMutableArray *idOfFriendsOnBanyan = [NSMutableArray arrayWithCapacity:[friendsOnBanyan count]];
                                             NSMutableArray *friendsOnBanyanMutable = [NSMutableArray arrayWithCapacity:[friendsOnBanyan count]];
                                             for (NSDictionary *friend in friendsOnBanyan) {
                                                 [idOfFriendsOnBanyan addObject:[friend objectForKey:@"objectId"]];
                                                 [friendsOnBanyanMutable addObject:[NSMutableDictionary dictionaryWithDictionary:friend]];
                                             }
                                             
                                             NSDictionary *constraint = [NSDictionary dictionaryWithObject:idOfFriendsOnBanyan forKey:@"$in"];    
                                             NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:kBNActivityTypeFollowUser, kBNActivityTypeKey,
                                                                             [User currentUser].userId, kBNActivityFromUserKey,
                                                                             constraint, kBNActivityToUserKey, nil];
                                             NSError *error = nil;
                                             NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
                                             if (!jsonData) {
                                                 NSLog(@"NSJSONSerialization failed %@", error);
                                             }
                                             NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                             NSDictionary *getFriendsBeingFollowed = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
                                             
                                             [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                                                           parameters:getFriendsBeingFollowed
                                                                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                                  NSDictionary *results = (NSDictionary *)responseObject;
                                                                                  NSMutableSet *userIdsBeingFollowed = [NSMutableSet set];
                                                                                  for (NSDictionary *user in [results objectForKey:@"results"]) {
                                                                                      [userIdsBeingFollowed addObject:[user objectForKey:kBNActivityToUserKey]];
                                                                                  }
                                                                                  for (NSMutableDictionary *userFriend in friendsOnBanyanMutable) {
                                                                                      if ([userIdsBeingFollowed containsObject:[userFriend objectForKey:@"objectId"]]) {
                                                                                          [userFriend setObject:[NSNumber numberWithBool:YES] forKey:USER_BEING_FOLLOWED];
                                                                                      } else {
                                                                                          [userFriend setObject:[NSNumber numberWithBool:NO] forKey:USER_BEING_FOLLOWED];
                                                                                      }
                                                                                  }
                                                                                  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                                                  [defaults setObject:friendsOnBanyanMutable forKey:BNUserDefaultsBanyanUsersFacebookFriends];
                                                                                  [defaults synchronize];
                                                                              }
                                                                              failure:AF_PARSE_ERROR_BLOCK()];
                                         }
                                         failure:AF_PARSE_ERROR_BLOCK()];
        
    } else {
        // We have users data
        // User info
        if ([result isKindOfClass:[NSDictionary class]] && [PFUser currentUser])
        {
            NSDictionary *resultsDict = result;
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if (![defaults objectForKey:BNUserDefaultsUserInfo]) {
                // User was not logged in previously
                [[NSNotificationCenter defaultCenter] postNotificationName:BNUserLogInNotification
                                                                    object:self];
            }
            [defaults setObject:resultsDict forKey:BNUserDefaultsUserInfo];
            [defaults synchronize];
            
            PFUser *currentUser = [PFUser currentUser];
            NSString *facebookId = [result objectForKey:@"id"];
            NSString *facebookFirstName = [result objectForKey:@"first_name"];
            NSString *facebookLastName = [result objectForKey:@"last_name"];
            NSString *facebookName = [result objectForKey:@"name"];
            NSString *facebookEmail = [resultsDict objectForKey:@"email"];
            
            [currentUser setEmail:facebookEmail];
            
            if (facebookFirstName && facebookFirstName != 0) {
                [currentUser setObject:facebookFirstName forKey:USER_FIRSTNAME];
            }
            
            if (facebookLastName && facebookLastName != 0) {
                [currentUser setObject:facebookLastName forKey:USER_LASTNAME];
            }
            
            if (facebookName && facebookName != 0) {
                [currentUser setObject:facebookName forKey:USER_NAME];
            }
            if (facebookId && facebookId != 0) {
                [currentUser setObject:facebookId forKey:USER_FACEBOOK_ID];
            }
            if (currentUser.isNew) {
                [currentUser setUsername:facebookEmail];
            }
            [currentUser saveEventually];
        }
        
        [PF_FBRequestConnection startForMyFriendsWithCompletionHandler:^(PF_FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self facebookRequest:connection didLoad:result];
            } else {
                [self facebookRequest:connection didFailWithError:error];
            }
        }];
    }
}

- (void)facebookRequest:(PF_FBRequestConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
        if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
             isEqualToString: @"OAuthException"]) {
            NSLog(@"The facebook token was invalidated");
            [self.userManagementModule logout];
        }
    }
}

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(PF_FBSession *)session
                      state:(PF_FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case PF_FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                NSLog(@"User session found");
            }
            break;
        case PF_FBSessionStateClosed:
        case PF_FBSessionStateClosedLoginFailed:
            [PF_FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BNFBSessionStateChangedNotification
                                                        object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

/*
 * Opens a Facebook session and optionally shows the login UX.
 */
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"email",
                            @"user_about_me",
                            nil];
    
    return [PF_FBSession openActiveSessionWithReadPermissions:permissions
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(PF_FBSession *session,
                                                             PF_FBSessionState state,
                                                             NSError *error) {
                                             [self sessionStateChanged:session
                                                                 state:state
                                                                 error:error];
                                         }];
}

@end

