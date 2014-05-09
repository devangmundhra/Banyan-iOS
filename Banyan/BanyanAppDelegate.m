//
//  BanyanAppDelegate.m
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BanyanAppDelegate.h"
#import "AFBanyanAPIClient.h"
#import "BanyanConnection.h"
#import "UserLoginViewController.h"
#import "User.h"
#import "BNAWSSNSClient.h"
#import "ECSlidingViewController.h"
#import "SideNavigatorViewController.h"
#import "StoryListTableViewController.h"
#import "SDWebImage/SDImageCache.h"
#import <AVFoundation/AVFoundation.h>
#import "UserVoice.h"
#import "MBProgressHUD.h"
#import "TWMessageBarManager.h"
#import "GAI.h"
#import <GoogleMaps/GoogleMaps.h>
#import "BNIntroViewController.h"
#import <AviarySDK/AviarySDK.h>

@interface BanyanAppDelegateTWMessageBarStyleSheet : NSObject <TWMessageBarStyleSheet>

+ (BanyanAppDelegateTWMessageBarStyleSheet *)styleSheet;

@end

@interface BanyanAppDelegate () <UserLoginViewControllerDelegate>
@property (strong, nonatomic) ECSlidingViewController *homeViewController;

@end

@implementation BanyanAppDelegate

@synthesize window = _window;
@synthesize homeViewController = _homeViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:@"defaultPerfs" ofType:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
    
    //let AFNetworking manage the activity indicator
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // Ask AWS iOS SDK not to throw exceptions. Return errors instead
    [AmazonErrorHandler shouldNotThrowExceptions];
    
    if (![[AFBanyanAPIClient sharedClient] isReachable])
        BNLogError(@"Banyan not reachable");
    
    if ([BanyanAppDelegate loggedIn] &&
        [FBSession openActiveSessionWithAllowLoginUI:NO]) {
        // User has Facebook ID.
        // Update user details and get updates on FB friends
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self updateUserCredentials:result withCompletionBlock:nil];
            } else {
                [self facebookRequest:connection didFailWithError:error];
            }
        }];
    } else {
        BNLogError(@"User missing Facebook ID");
        [self logout];
    }
    
    // RestKit initialization
    RKLogConfigureByName("RestKit", RKLogLevelWarning);
    RKLogConfigureByName("RestKit/*", RKLogLevelWarning);
//    RKLogConfigureByName("RestKit/Network*", RKLogLevelWarning);
//    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelWarning);
//    RKLogConfigureByName("RestKit/CoreData", RKLogLevelWarning);
    
    [self restKitCoreDataInitialization];
    
    [RemoteObject validateAllObjects];
    [GMSServices provideAPIKey:GOOGLE_IOS_API_KEY];
    [self googleAnalyticsInitialization];
    
    [Crashlytics startWithAPIKey:CRASHLYTICS_API_KEY];
    
    UVConfig *config = [UVConfig configWithSite:@"banyan.uservoice.com"];
    [UVStyleSheet instance].tintColor = BANYAN_GREEN_COLOR;
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (currentUser) {
        [config identifyUserWithEmail:currentUser.email name:currentUser.name guid:[NSString stringWithFormat:@"%@", currentUser.userId]];
        [Crashlytics setUserIdentifier:[NSString stringWithFormat:@"%@", currentUser.userId]];
    }
    [UserVoice initialize:config];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AFPhotoEditorController setAPIKey:AVIARY_KEY secret:AVIARY_SECRET];
    });
    [AFOpenGLManager beginOpenGLLoad];
    
    // Register for push notifications only after the user has logged in
    if ([BanyanAppDelegate loggedIn]) {
        [application registerForRemoteNotificationTypes:
         UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert];
    }
    
    [self appearances];
    
    self.homeViewController = [ECSlidingViewController slidingWithTopViewController:[[UINavigationController alloc] initWithRootViewController:[[StoryListTableViewController alloc] init]]];
    self.homeViewController.underLeftViewController = [[SideNavigatorViewController alloc] init];
    self.window.rootViewController = self.homeViewController;
    [self.window makeKeyAndVisible];
    
    [self showIntroIfRequired];
    
    // Extract the notification data
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [self application:application didReceiveRemoteNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
    }

    return YES;
}

- (void) showIntroIfRequired
{
    if ([BNMisc isFirstTimeUserAction:BNUserDefaultsFirstTimeAppOpen]) {
        BNIntroViewController *introVC = [[BNIntroViewController alloc] init];
        [self.window.rootViewController presentViewController:introVC animated:NO completion:nil];
    }
}

void uncaughtExceptionHandler(NSException *exception)
{
    BNLogError(@"CRASH: %@", exception);
    BNLogError(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

- (void) googleAnalyticsInitialization
{
    // set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelError];
    
#ifdef DEBUG
    [GAI sharedInstance].dryRun = YES;
#endif

    // Initialize tracker.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS_ID];
    BNLogTrace(@"Google Analytics tracker iniitialized %@", tracker);
}

#pragma mark customize appearnaces
- (void) appearances
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

    [self.window setTintColor:BANYAN_GREEN_COLOR];
    
    [[UISwitch appearance] setOnTintColor:BANYAN_GREEN_COLOR];
    
    [[UITabBar appearance] setSelectedImageTintColor:BANYAN_BROWN_COLOR];
    
    [TWMessageBarManager sharedInstance].styleSheet = [BanyanAppDelegateTWMessageBarStyleSheet styleSheet];
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
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Cancel GET requests for fetching stories when app is going in background
    [[RKObjectManager sharedManager] cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"story/"];
    NSError *error = nil;
    if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
        NSAssert2(false, @"Unresolved Core Data Save error %@", error, [error userInfo]);
    }
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
//    [BanyanConnection uploadFailedObjects];
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
    // Save the device token
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceToken forKey:BNUserDefaultsDeviceToken];
    [defaults synchronize];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
//    [BNAWSSNSClient registerDeviceToken:@"1111111111111111111111111111111111111111111111111111111111111111"];
    [BNMisc sendGoogleAnalyticsError:error inAction:@"register for remote notification" isFatal:NO];
    BNLogWarning(@"Failed to register for notification for error: %@", error.localizedDescription);
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    BNLogInfo(@"Handling push with info: %@", userInfo);
    
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Banyan" description:[aps objectForKey:@"alert"] type:TWMessageBarMessageTypeInfo];
        [self loadRemoteObjectFromUserInfo:userInfo displayIfPossible:NO];
    } else {
        //Do stuff that you would do if the application was not active
        [self loadRemoteObjectFromUserInfo:userInfo displayIfPossible:YES];
    }
}

- (void) loadRemoteObjectFromUserInfo:(NSDictionary *)userInfo displayIfPossible:(BOOL)display
{
#define OP_TIMEOUT_INTERVAL 12
    NSDictionary *dataDict = [userInfo objectForKey:@"data"];
    NSString *storyId = [dataDict objectForKey:@"story"];
    NSString *pieceId = [dataDict objectForKey:@"piece"];
    NSDate *opStartDate = [NSDate date];

    if (storyId) {
        UINavigationController *topNavController = nil;
        StoryListTableViewController *topStoryListVC = nil;
        __block MBProgressHUD *hud = nil;
        
        if ([[self topMostController] isKindOfClass:[ECSlidingViewController class]] && [self.homeViewController.topViewController isKindOfClass:[UINavigationController class]]) {
            topNavController = (UINavigationController *)self.homeViewController.topViewController;
            
            if ([topNavController.topViewController isKindOfClass:[StoryListTableViewController class]]) {
                topStoryListVC = (StoryListTableViewController *)topNavController.topViewController;
                RUN_SYNC_ON_MAINTHREAD(^{
                    hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
                    hud.mode = MBProgressHUDModeIndeterminate;
                    hud.labelText = pieceId ? @"Trying to fetch piece from the server" : @"Trying to fetch story from the server";
                    hud.labelFont = [UIFont fontWithName:@"Roboto" size:12];
                    [hud hide:YES afterDelay:OP_TIMEOUT_INTERVAL];
                });
            }
        }
        __weak typeof(hud) whud = hud;

        // There was a new story. Get the story and launch it
        [[RKObjectManager sharedManager] getObjectsAtPath:[NSString stringWithFormat:@"story/%@/?format=json", storyId]
                                               parameters:nil
                                                  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                      // Reset the badge to zero
                                                      [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
                                                      NSTimeInterval opInterval = [opStartDate timeIntervalSinceNow];
                                                      if (opInterval < -OP_TIMEOUT_INTERVAL) {
                                                          // We give OP_TIMEOUT_INTERVAL seconds from the app launch for the story to be successfully
                                                          // received and opened, so that if a user starts another operation, he/she is not
                                                          // interrupted by some random story being opened
                                                          BNLogInfo(@"Ignoring action from notificaiton as operation interval was %f seconds", opInterval);
                                                          return;
                                                      }
                                                      NSArray *stories = [mappingResult array];
                                                      NSAssert1(stories.count <= 1, @"Error in getting a single story from remote notificaiton", storyId);
                                                      Story *story = [stories lastObject];
                                                      if (story) {
                                                          Piece *piece = nil;
                                                          if (pieceId) {
                                                              // Open the story with the specific piece
                                                              piece = [Piece pieceForStory:story withAttribute:@"bnObjectId" asValue:pieceId];
                                                          } else {
                                                              // Open the story from the first piece
                                                              if (story.pieces.count > 0) {
                                                                  piece = [story.pieces objectAtIndex:0];
                                                              }
                                                          }
                                                          // Story reader, open piece
                                                          if (piece && topStoryListVC && display) {
                                                              // If the top view controller is a StoryListController, then read the story, otherwise nothing
                                                              [self.homeViewController resetTopViewAnimated:NO onComplete:nil];
                                                              StoryListTableViewController *topStoryListVC = (StoryListTableViewController *)topNavController.topViewController;
                                                              [topStoryListVC storyReaderWithStory:story piece:piece];
                                                          }
                                                      }
                                                      RUN_SYNC_ON_MAINTHREAD(^{[whud hide:YES];});
                                                  }
                                                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                      RUN_SYNC_ON_MAINTHREAD(^{[whud hide:YES];});
                                                  }];
        
    } else {
        // Do nothing
    }
}

# pragma mark User Account Management
- (void)login
{
    // animate the tabbar up to the screen
    UserLoginViewController *userLoginViewController = [[UserLoginViewController alloc] initWithNibName:@"UserLoginViewController" bundle:nil];
    userLoginViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:userLoginViewController];
    [self.homeViewController presentViewController:navController animated:YES completion:nil];
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
    
    // Set the page to the home page
    [self.homeViewController setTopViewController:[[UINavigationController alloc] initWithRootViewController:[[StoryListTableViewController alloc] init]]];
    return;
}

# pragma mark UserLoginViewControllerDelegate methods
- (void) loginViewControllerDidLoginWithFacebookUser:(id<FBGraphUser>)user withCompletionBlock:(void (^)(bool succeeded, NSError *error))block
{
    [self updateUserCredentials:user withCompletionBlock:block];
}


- (void) updateUserCredentials:(id<FBGraphUser>)user withCompletionBlock:(void (^)(bool succeeded, NSError *error))block
{
    NSString *accessToken = [[FBSession.activeSession accessTokenData] accessToken];
    NSMutableDictionary *postInfo = [NSMutableDictionary dictionary];
    /* 
     * For now don't send the user info. Once the app pulls the info from facebook,
     * lets just use it that way. This is because we might allow a person to change his/her name on
     * the app in the future. Just send the new access token that was retrieved from facebook.
    [postInfo setObject:user.first_name forKey:@"first_name"];
    [postInfo setObject:user.last_name forKey:@"last_name"];
    [postInfo setObject:user.name forKey:@"name"];
    [postInfo setObject:[user objectForKey:@"email"] forKey:@"email"];
     */
    [postInfo setObject:@{@"access_token": accessToken, @"id": user.id} forKey:@"facebook"];
    
    [[AFBanyanAPIClient sharedClient] postPath:@"users/"
                                    parameters:postInfo
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
                                           
                                           // Set the header authorizations so that the api knows who the user is
                                           NSString *username = [userInfo objectForKey:@"username"];
                                           NSString *apikey = [userInfo objectForKey:@"api_key"];
                                           [[ RKObjectManager sharedManager].HTTPClient
                                            setAuthorizationHeaderWithTastyPieUsername:username
                                            andToken:apikey];
                                           
                                           NSString *deviceToken = [defaults objectForKey:BNUserDefaultsDeviceToken];

                                           // Tell AWS SNS about the device token.
                                           [BNAWSSNSClient registerDeviceToken:deviceToken withCompletionBlock:^{
                                               [self subscribeToPushNotifications];
                                           }];
                                           if (block) {
                                               block(YES, nil);
                                           }
                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           if (block) {
                                               block(NO, error);
                                           }
                                       }];
}

- (void) subscribeToPushNotifications
{
    // Enable or disable endpoint arn depending upon the preference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL on;
    
    on = [defaults boolForKey:BNUserDefaultsAddStoryInvitedContributePushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_INVTOCONTRIBUTE forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSInvitedToContributeString] inBackgroundWithBlock:nil];
    }
    
    on = [defaults boolForKey:BNUserDefaultsAddStoryInvitedViewPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_INVTOVIEW forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSInvitedToViewString] inBackgroundWithBlock:nil];
    }
    
    on = [defaults boolForKey:BNUserDefaultsAddPieceToContributedStoryPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_PIECEADDED forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSPieceAddedString] inBackgroundWithBlock:nil];
    }
    
    on = [defaults boolForKey:BNUserDefaultsPieceActionPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_PIECEACTION forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSPieceActionString] inBackgroundWithBlock:nil];
    }
    
    on = [defaults boolForKey:BNUserDefaultsUserFollowingPushNotification];
    if (on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_USERFOLLOWING forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSUserFollowingString] inBackgroundWithBlock:nil];
    }
}

- (void) unsubscribeFromAllPushNotifications
{
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_INVTOCONTRIBUTE forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSInvitedToContributeString] inBackgroundWithBlock:nil];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_INVTOVIEW forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSInvitedToViewString] inBackgroundWithBlock:nil];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_PIECEACTION forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSPieceActionString] inBackgroundWithBlock:nil];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_PIECEADDED forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSPieceAddedString] inBackgroundWithBlock:nil];
    [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_USERFOLLOWING forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:BNAWSSNSUserFollowingString] inBackgroundWithBlock:nil];
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
    BNLogError(@"Facebook error: %@", error);
    
    if ([BanyanAppDelegate loggedIn]) {
        if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
             isEqualToString: @"OAuthException"]) {
            BNLogInfo(@"The facebook token was invalidated");
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
                BNLogInfo(@"User session found");
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
    NSError *error;
    BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
    if (! success) {
        RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
    }
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Banyan.sqlite"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath
                                                                     fromSeedDatabaseAtPath:nil
                                                                          withConfiguration:nil
                                                                                    options:options
                                                                                      error:&error];
    
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);

    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
    managedObjectStore.persistentStoreManagedObjectContext.undoManager = nil;
    managedObjectStore.mainQueueManagedObjectContext.undoManager = nil;
    
    [RKManagedObjectStore setDefaultStore:managedObjectStore];
    
    BNLogTrace(@"\rPersistent Store Ctx: %@\rMain Ctx: %@", managedObjectStore.persistentStoreManagedObjectContext, managedObjectStore.mainQueueManagedObjectContext);
}

#pragma mark MISCELLANEOUS METHODS
- (UIViewController*) topMostController
{
    UIViewController *topController = self.window.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark
#pragma mark Memory Management
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{

}

@end

@implementation BanyanAppDelegateTWMessageBarStyleSheet

#pragma mark - Alloc/Init

+ (BanyanAppDelegateTWMessageBarStyleSheet *)styleSheet
{
    return [[BanyanAppDelegateTWMessageBarStyleSheet alloc] init];
}

#pragma mark - TWMessageBarStyleSheet

- (UIColor *)backgroundColorForMessageType:(TWMessageBarMessageType)type
{
    UIColor *backgroundColor = nil;
    switch (type)
    {
        case TWMessageBarMessageTypeError:
            backgroundColor = BANYAN_RED_COLOR;
            break;
        case TWMessageBarMessageTypeSuccess:
            backgroundColor = BANYAN_GREEN_COLOR;
            break;
        case TWMessageBarMessageTypeInfo:
            backgroundColor = [BANYAN_DARKGRAY_COLOR colorWithAlphaComponent:0.9];
            break;
        default:
            break;
    }
    return backgroundColor;
}

- (UIColor *)strokeColorForMessageType:(TWMessageBarMessageType)type
{
    UIColor *strokeColor = nil;
    switch (type)
    {
        case TWMessageBarMessageTypeError:
            strokeColor = BANYAN_RED_COLOR;
            break;
        case TWMessageBarMessageTypeSuccess:
            strokeColor = BANYAN_GREEN_COLOR;
            break;
        case TWMessageBarMessageTypeInfo:
            strokeColor = [BANYAN_DARKGRAY_COLOR colorWithAlphaComponent:0.9];
            break;
        default:
            break;
    }
    return strokeColor;
}

- (UIImage *)iconImageForMessageType:(TWMessageBarMessageType)type
{
    return nil;
}

@end