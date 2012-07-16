//
//  AppDelegate.m
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "AppDelegate.h"
#import "ParseAPIEngine.h"
#import "BanyanAPIEngine.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize userManagementModule;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    //    [NIOverview applicationDidFinishLaunching];
    //    [NIOverview addOverviewToWindow:self.window];
    
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
    
    [TestFlight takeOff:@"072cbecbb96cfd6e4593af01f8bbfb72_MTAyMjk0MjAxMi0wNi0yOCAwMToyNTo0OC43NDAyMzU"];
    
    // Create a location manager instance to determine if location services are enabled. This manager instance will be
    // immediately released afterwards.
    if ([CLLocationManager locationServicesEnabled] == NO) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        [TestFlight passCheckpoint:@"AppDelegate All location services disabled alert"];
    }
    [self appearances];
    
    [Parse setApplicationId:PARSE_APP_ID 
                  clientKey:PARSE_CLIENT_KEY];
    userManagementModule = [[UserManagementModule alloc] init];
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert];
    
    // There seems to be a problem with calling these functions the first time (giving false negatives)
    // So just call them here as a null function
    [[ParseAPIEngine sharedEngine] isReachable];
    [[BanyanAPIEngine sharedEngine] isReachable];
    
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
}

#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark FacebookSessionDelegate

// Pre iOS 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    //    return [userManagementModule.facebook handleOpenURL:url]; 
    return [PFFacebookUtils handleOpenURL:url];
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    //    return [userManagementModule.facebook handleOpenURL:url]; 
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
@end

