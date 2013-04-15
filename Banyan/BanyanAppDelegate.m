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
#import "AFBanyanAPIClient.h"
#import "StoryListTableViewController.h"

@implementation BanyanAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize navController = _navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    // Normal launch stuff
    
    [Parse setApplicationId:PARSE_APP_ID
                  clientKey:PARSE_CLIENT_KEY];
    
    // Override point for customization after application launch.
    [PFFacebookUtils initializeFacebook];
    
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
    
    [TestFlight takeOff:TESTFLIGHT_BANYAN_TEAM_TOKEN];
    
    //let AFNetworking manage the activity indicator
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // RestKit initialization
    RKLogConfigureByName("RestKit/Network*", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);
    
    [self restKitCoreDataInitialization];
    
    if (![[AFParseAPIClient sharedClient] isReachable])
        NSLog(@"Parse not reachable");
    
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
        
    if ([BanyanAppDelegate loggedIn]) {
        // User has Facebook ID.
        // Update user details and get updates on FB friends
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
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
    
    [self setupTabBarController];
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.tabBarController];
    self.navController.navigationBarHidden = YES;
    
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];
    
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
    [[UINavigationBar appearance] setTintColor:BANYAN_GREEN_COLOR];
    
    [[UIToolbar appearance] setTintColor:BANYAN_BROWN_COLOR];
    
    [[UIBarButtonItem appearance] setTintColor:BANYAN_GREEN_COLOR];
    
    [[UISwitch appearance] setOnTintColor:BANYAN_GREEN_COLOR];
    
    [[UISegmentedControl appearance] setTintColor:BANYAN_GREEN_COLOR];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    [[UISlider appearance] setThumbTintColor:BANYAN_GREEN_COLOR];
    
    [[UISlider appearance] setMinimumTrackTintColor:BANYAN_BROWN_COLOR];
    
    [[UITabBar appearance] setSelectedImageTintColor:BANYAN_BROWN_COLOR];
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

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
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
    [FBSession.activeSession handleDidBecomeActive];
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
    // Tell Parse about the device token.
    [PFPush storeDeviceToken:newDeviceToken];
    // Subscribe to the global broadcast channel.
    [PFPush subscribeToChannelInBackground:@""];
}

- (void)application:(UIApplication *)application 
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

# pragma mark User Account Management
- (void)login
{
    // animate the tabbar up to the screen
    UserLoginViewController *userLoginViewController = [[UserLoginViewController alloc] init];
    userLoginViewController.delegate = self;
    userLoginViewController.facebookPermissions = [NSArray arrayWithObjects: @"email", @"user_about_me", nil];
    [self.navController presentViewController:userLoginViewController animated:YES completion:nil];
}

- (void)logout
{    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:BNUserDefaultsUserInfo];
    [defaults removeObjectForKey:BNUserDefaultsFacebookFriends];
    [defaults synchronize];
    [PFPush unsubscribeFromChannelInBackground:[[PFUser currentUser] objectId]];
    [PFUser logOut];
    [[NSNotificationCenter defaultCenter] postNotificationName:BNUserLogOutNotification
                                                        object:nil];
    return;
}

+ (BOOL)loggedIn
{
    if ([PFUser currentUser] && // Check if a user is cached
        [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) // Check if user is linked to Facebook
    {
        return YES;
    }
    return NO;
}

- (void)facebookRequest:(FBRequestConnection *)connection didLoad:(id)result
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
                                                                             [PFUser currentUser].objectId, kBNActivityFromUserKey,
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
            [currentUser saveEventually:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    NSLog(@"%s User could not be updated because of error %@. Logging out", __PRETTY_FUNCTION__, error);
                    [self logout];
                }
            }];
        }
        
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self facebookRequest:connection didLoad:result];
            } else {
                [self facebookRequest:connection didFailWithError:error];
            }
        }];
    }
}

- (void)facebookRequest:(FBRequestConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
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
                                                                          withConfiguration:nil options:nil
                                                                                      error:&error];
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
    NSLog(@"BanyanAppDelegate MainMOC %@ PersistentMOC %@", managedObjectStore.mainQueueManagedObjectContext, managedObjectStore.persistentStoreManagedObjectContext);
    
    [RKManagedObjectStore setDefaultStore:managedObjectStore];
}

#pragma mark MISCELLANEOUS METHODS
+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark TabBar Controller Methods
- (void)setupTabBarController
{
    self.tabBarController = [[BNTabBarController alloc] init];
    StoryListTableViewController *storyListVC = [[StoryListTableViewController alloc] init];
    storyListVC.title = @"Stories";
    
    UITabBarItem *storyListTabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"homeTabSymbol"] tag:0];
    
    UITableViewController *searchVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    UITabBarItem *searchTabBarItem = [[UITabBarItem alloc] initWithTitle:@"Search" image:[UIImage imageNamed:@"searchTabSymbol"] tag:0];
    
    NewStoryViewController *newStoryViewController = [[NewStoryViewController alloc] initWithNibName:@"NewStoryViewController" bundle:nil];
    newStoryViewController.delegate = self;
    UITabBarItem *addTabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"addTabSymbol"] tag:0];
    
    SettingsTableViewController *settingsVC = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UITabBarItem *settingsTabBar = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"userProfileTabSymbol"] tag:0];
    
    UINavigationController *storyListNavigationController = [[UINavigationController alloc] initWithRootViewController:storyListVC];
    UINavigationController *addNavigationController = [[UINavigationController alloc] initWithRootViewController:newStoryViewController];
    UINavigationController *searchNavigationController = [[UINavigationController alloc] initWithRootViewController:searchVC];
    UINavigationController *profileNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsVC];

    [storyListNavigationController setTabBarItem:storyListTabBarItem];
    [searchNavigationController setTabBarItem:searchTabBarItem];
    [addNavigationController setTabBarItem:addTabBarItem];
    [profileNavigationController setTabBarItem:settingsTabBar];

    self.tabBarController.delegate = self;
    [self.tabBarController setViewControllers:@[storyListNavigationController, /*searchNavigationController,*/ addNavigationController, profileNavigationController] animated:YES];
}

- (void) newStoryViewController:(NewStoryViewController *)sender
                    didAddStory:(Story *)story
{
    // Can't add a story to the scene yet because the story Id would not be furnished here.
    //    [self addSceneToStory:story];
}

- (void) newStoryViewControllerDidCancel:(NewStoryViewController *)sender
{
}

# pragma mark UserLoginViewControllerDelegate
- (void)logInViewController:(UserLoginViewController *)logInController didLogInUser:(PFUser *)user
{
    NSLog(@"Getting user info");
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            [(BanyanAppDelegate *)[[UIApplication sharedApplication] delegate] facebookRequest:connection didLoad:result];
        } else {
            [(BanyanAppDelegate *)[[UIApplication sharedApplication] delegate] facebookRequest:connection didFailWithError:error];
        }
    }];
    [PFPush subscribeToChannelInBackground:[[PFUser currentUser] objectId]];
}

@end

