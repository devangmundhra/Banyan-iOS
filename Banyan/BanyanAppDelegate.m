//
//  BanyanAppDelegate.m
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BanyanAppDelegate.h"
#import "User_Defines.h"
#import "AFBanyanAPIClient.h"
#import "BanyanConnection.h"
#import "MasterTabBarController.h"
#import "UserLoginViewController.h"
#import "User.h"
#import "BNAWSSNSClient.h"

@interface BanyanAppDelegate () <UserLoginViewControllerDelegate>
@property (strong, nonatomic) NSTimer *remoteObjectBackgroundTimer;

@end

@implementation BanyanAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize remoteObjectBackgroundTimer = _remoteObjectBackgroundTimer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:@"defaultPerfs" ofType:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
    
#define TESTING 1
#ifdef TESTING
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"UUID"]) {
        [TestFlight setDeviceIdentifier:[defaults objectForKey:@"UUID"]];
    } else {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        NSString *uuidString = (__bridge_transfer NSString *)string;
        [defaults setObject:uuidString forKey:@"UUID"];
        [defaults synchronize];
        [TestFlight setDeviceIdentifier:uuidString];
    }
#endif
    
    [TestFlight takeOff:TESTFLIGHT_BANYAN_APP_TOKEN];
    
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert];
    
    //let AFNetworking manage the activity indicator
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // RestKit initialization
    RKLogConfigureByName("RestKit/Network*", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);
    
    [self restKitCoreDataInitialization];
    
    if (![[AFBanyanAPIClient sharedClient] isReachable])
        NSLog(@"Banyan not reachable");
    
    // Create a location manager instance to determine if location services are enabled. This manager instance will be
    // immediately released afterwards.
    if ([CLLocationManager locationServicesEnabled] == NO) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        [TestFlight passCheckpoint:@"AppDelegate All location services disabled alert"];
    }
    
    [self appearances];
    
    if ([BanyanAppDelegate loggedIn] &&
        [FBSession openActiveSessionWithAllowLoginUI:NO]) {
        // User has Facebook ID.
        // Update user details and get updates on FB friends
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self updateUserCredentials:result];
            } else {
                [self facebookRequest:connection didFailWithError:error];
            }
        }];
    } else {
        NSLog(@"User missing Facebook ID");
        [self logout];
    }
        
    self.tabBarController = [[MasterTabBarController alloc] init];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    // Extract the notification data
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    [BanyanAppDelegate handlePush:notificationPayload];
    
    return YES;
}

void uncaughtExceptionHandler(NSException *exception)
{
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

#pragma mark customize appearnaces
- (void) appearances
{
    if (!DEVICE_VERSION_7PLUS) {
        [[UINavigationBar appearance] setTintColor:BANYAN_GREEN_COLOR];
        [[UIBarButtonItem appearance] setTintColor:BANYAN_GREEN_COLOR];
    }
    
    [[UISwitch appearance] setOnTintColor:BANYAN_GREEN_COLOR];
    
    [[UITabBar appearance] setSelectedImageTintColor:BANYAN_BROWN_COLOR];
}

#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
+ (NSURL *)applicationDocumentsDirectory
{
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    return documentsDirectoryURL;
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL urlWasHandled = [FBAppCall handleOpenURL:url
                                sourceApplication:sourceApplication
                                  fallbackHandler:^(FBAppCall *call) {
                                      // handle deep links and responses for Login or Share Dialog here
                                  }];
    
    return urlWasHandled;
}

#pragma mark application methods

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self invalidateRemoteObjectTimer];
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
    [RemoteObject validateAllObjects];

    [FBSession.activeSession handleDidBecomeActive];
    
    if ([[AFBanyanAPIClient sharedClient] isReachable])
        [self fireRemoteObjectTimer];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [FBSession.activeSession close];
}

# pragma mark push notifications
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    NSString* deviceToken = [[[[newDeviceToken description]
                                stringByReplacingOccurrencesOfString: @"<" withString: @""]
                               stringByReplacingOccurrencesOfString: @">" withString: @""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""];
    // Tell AWS SNS about the device token.
    [BNAWSSNSClient registerDeviceToken:[NSString stringWithFormat:@"%@", deviceToken]];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register for notification for error: %@", error.localizedDescription);
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [BanyanAppDelegate handlePush:userInfo];
}

+ (void) handlePush:(NSDictionary *)userInfo
{
    NSLog(@"Handing push with info: %@", userInfo);
}

# pragma mark User Account Management
- (void)login
{
    // animate the tabbar up to the screen
    UserLoginViewController *userLoginViewController = [[UserLoginViewController alloc] initWithNibName:@"UserLoginViewController" bundle:nil];
    userLoginViewController.delegate = self;
    [self.tabBarController presentViewController:userLoginViewController animated:YES completion:nil];
}

- (void)logout
{
    // Unsubscribe before removing the userinfo from NSUserDefaults
    [self unsubscribeFromAllPushNotifications];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:BNUserDefaultsUserInfo];
    [defaults synchronize];
    [FBSession.activeSession closeAndClearTokenInformation];
    // Delete API_KEY information so that APIAuthentication is not triggered by the server
    [[AFBanyanAPIClient sharedClient] clearAuthorizationHeader];
    // Clear cookies so that SessionAuthentication does not pass in the server
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:BNUserLogOutNotification
                                                        object:nil];
    return;
}

# pragma mark UserLoginViewControllerDelegate methods
- (void) loginViewControllerDidLoginWithFacebookUser:(id<FBGraphUser>)user
{
    [self updateUserCredentials:user];
}


- (void) updateUserCredentials:(id<FBGraphUser>)user
{
    NSString *accessToken = [[FBSession.activeSession accessTokenData] accessToken];
    [[AFBanyanAPIClient sharedClient] postPath:@"users/"
                                    parameters:@{@"facebook": @{@"access_token": accessToken, @"id": user.id}}
                                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                           BOOL shouldNotifyUserLogin = ![BanyanAppDelegate loggedIn];
                                           NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
                                           // TODO: Get friends the user is actually following instead of just the facebook friends on banyan
                                           NSArray *fbFriends = [[[[userInfo objectForKey:@"social_data"] objectForKey:@"facebook"] objectForKey:@"friends_on_banyan"] copy];
                                           [userInfo removeObjectForKey:@"social_data"];
                                           NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                           [defaults setObject:userInfo forKey:BNUserDefaultsUserInfo];
                                           [defaults setObject:fbFriends forKey:BNUserDefaultsBanyanUsersFacebookFriends];
                                           [defaults synchronize];

                                           if (shouldNotifyUserLogin) {
                                               // User was not logged in previously
                                               [[NSNotificationCenter defaultCenter] postNotificationName:BNUserLogInNotification
                                                                                                   object:self];
                                           }
                                           [self subscribeToPushNotifications];
                                           
                                           // Set the header authorizations so that the api knows who the user is
                                           NSString *email = [userInfo objectForKey:@"email"];
                                           NSString *apikey = [userInfo objectForKey:@"api_key"];
                                           [[AFBanyanAPIClient sharedClient] setAuthorizationHeaderWithUsername:email apikey:apikey];
                                           
                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           NSLog(@"An error occurred: %@", error.localizedDescription);
                                       }];
}

- (void) subscribeToPushNotifications
{
    // Enable or disable endpoint arn depending upon the preference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL on;
    
    on = [defaults boolForKey:BNUserDefaultsAddStoryInvitedContributePushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_INVTOCONTRIBUTE forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"InvitedToContribute"]];
    }
    
    on = [defaults boolForKey:BNUserDefaultsAddStoryInvitedViewPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_INVTOVIEW forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"InvitedToView"]];
    }
    
    on = [defaults boolForKey:BNUserDefaultsAddPieceToContributedStoryPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_PIECEADDED forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"PieceAdded"]];
    }
    
    on = [defaults boolForKey:BNUserDefaultsPieceActionPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_PIECEACTION forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"PieceAction"]];
    }
    
    on = [defaults boolForKey:BNUserDefaultsUserFollowingPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_USERFOLLOWING forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"UserFollowing"]];
    }
}

- (void) unsubscribeFromAllPushNotifications
{
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_INVTOCONTRIBUTE forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"InvitedToContribute"]];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_INVTOVIEW forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"InvitedToView"]];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_PIECEACTION forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"PieceAction"]];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_PIECEADDED forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"PieceAdded"]];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_USERFOLLOWING forEndpointArn:[[BNAWSSNSClient getEndpointsDict] objectForKey:@"UserFollowing"]];
}

+ (BOOL)loggedIn
{
    if ([[NSUserDefaults standardUserDefaults] dictionaryForKey:BNUserDefaultsUserInfo]) // Check if user is linked to Facebook
    {
        return YES;
    }
    return NO;
}

- (void)facebookRequest:(FBRequestConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Facebook error: %@", error);
    
    if ([BanyanAppDelegate loggedIn]) {
        if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
             isEqualToString: @"OAuthException"]) {
            NSLog(@"The facebook token was invalidated");
            [self logout];
        }
    }
}

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                // We have a valid session
                NSLog(@"User session found");
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
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
    
    return [FBSession openActiveSessionWithReadPermissions:permissions
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session,
                                                             FBSessionState state,
                                                             NSError *error) {
                                             [self sessionStateChanged:session
                                                                 state:state
                                                                 error:error];
                                         }];
}

- (void) restKitCoreDataInitialization
{
    // Initialize managed object store
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    /**
     Complete Core Data stack initialization
     */
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Banyan.sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath
                                                                     fromSeedDatabaseAtPath:nil
                                                                          withConfiguration:nil
                                                                                    options:nil
                                                                                      error:&error];
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
    managedObjectStore.persistentStoreManagedObjectContext.undoManager = nil;
    managedObjectStore.mainQueueManagedObjectContext.undoManager = nil;
    
    NSLog(@"BanyanAppDelegate MainMOC %@ PersistentMOC %@ Persistent Store: %@", managedObjectStore.mainQueueManagedObjectContext, managedObjectStore.persistentStoreManagedObjectContext, persistentStore);
    
    [RKManagedObjectStore setDefaultStore:managedObjectStore];
}

#pragma mark MISCELLANEOUS METHODS
+ (UIViewController*) topMostController
{
    UIViewController *topController = ((BanyanAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark Background Timer to upload unsaved objects
- (void) fireRemoteObjectTimer
{
    if (!self.remoteObjectBackgroundTimer)
        // Instantiate the background timer to process uploading of failed remote objects every minute
        self.remoteObjectBackgroundTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                            target:[BanyanConnection class]
                                                                          selector:@selector(uploadFailedObjects)
                                                                          userInfo:nil
                                                                           repeats:YES];
    [self.remoteObjectBackgroundTimer fire];
}

- (void) invalidateRemoteObjectTimer
{
    [self.remoteObjectBackgroundTimer invalidate];
    self.remoteObjectBackgroundTimer = nil;
}

@end

