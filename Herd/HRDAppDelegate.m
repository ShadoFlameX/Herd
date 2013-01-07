//
//  HRDAppDelegate.m
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import "HRDAppDelegate.h"
#import "HRDMapViewController.h"
#import "HRDAPI.h"
#import "NSUserDefaults+Herd.h"

static CGFloat const EventSecondsProximity = 30.0f * 66.0f;

@interface HRDAppDelegate () {
    CLLocationManager *_locationManager;
    UIBackgroundTaskIdentifier _backgroundLocationTask;
}

@end

@implementation HRDAppDelegate

#pragma mark - Properties

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.distanceFilter = 10;
    }
    
    return _locationManager;
}


#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([NSUserDefaults standardUserDefaults].trackingUser) {
        [self updateTrackingStatus];
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound |
                                                                           UIRemoteNotificationTypeAlert)];

    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[HRDMapViewController alloc] initWithNibName:@"HRDMapViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self updateTrackingStatus];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self updateTrackingStatus];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Push Notifications

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"didReceiveRemoteNotification: %@",userInfo);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *deviceTokenString = [[[[deviceToken description]
                                     stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                    stringByReplacingOccurrencesOfString: @">" withString: @""]
                                   stringByReplacingOccurrencesOfString: @" " withString: @""];

    [NSUserDefaults standardUserDefaults].registeredDeviceToken = deviceTokenString;
        
    NSLog(@"My token is: %@", deviceTokenString);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
    
    [NSUserDefaults standardUserDefaults].registeredDeviceToken = @"4";
}


#pragma mark - CLLocationManagerDelegate

- (void)updateTrackingStatus
{
    NSDate *eventDate = [NSUserDefaults standardUserDefaults].eventDate;
    
    NSTimeInterval secondsSinceEvent = [[NSDate date] timeIntervalSinceDate:eventDate];
    
    if (!eventDate || secondsSinceEvent > EventSecondsProximity) {
        [NSUserDefaults standardUserDefaults].trackingUser = NO;
    }
    
    if (![NSUserDefaults standardUserDefaults].trackingUser) {
        [self.locationManager stopUpdatingLocation];
        return;
    }
    
    BOOL isInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
        
    BOOL isCloseToEvent = fabs(secondsSinceEvent) < EventSecondsProximity;
    
    if (isCloseToEvent || !isInBackground) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager startUpdatingLocation];
        
    } else {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    BOOL isInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
    
    if (locations.count) {
        [self sendLocationUpdate:locations[locations.count - 1] isInBackground:isInBackground];
    };
}

- (void)sendLocationUpdate:(CLLocation *)location isInBackground:(BOOL)isInBackground
{
    if (isInBackground) {
        NSLog(@"Sending location update in background: %@", location);
        
        _backgroundLocationTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundLocationTask];
        }];
        
        [HRDAPI updateUserWithLocation:location.coordinate];
        
        if (_backgroundLocationTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundLocationTask];
            _backgroundLocationTask = UIBackgroundTaskInvalid;
        }
        
    } else {
        NSLog(@"Sending location update in foreground: %@", location);
        
        [HRDAPI updateUserWithLocation:location.coordinate];
    }
}

@end
