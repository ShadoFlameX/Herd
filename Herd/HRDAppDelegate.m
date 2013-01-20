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

static CGFloat const EventSecondsProximity = 30.0f * 60.0f;

typedef enum {
    EventTimeProximityBefore = 0,
    EventTimeProximitySoonBefore,
    EventTimeProximitySoonAfter,
    EventTimeProximityAfter
} EventTimeProximity;

@interface HRDAppDelegate () {
    CLLocationManager *_locationManager;
    UIBackgroundTaskIdentifier _backgroundLocationTask;
    BOOL _isTrackingLocationAccurately;
    BOOL _isUpdatingEvent;
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
    }
    
    return _locationManager;
}


#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _isTrackingLocationAccurately = NO;

    if ([NSUserDefaults standardUserDefaults].trackingUser) {
        [self updateTrackingStatus];
    }
    
    [self updateEvent];
    
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
    [self updateEvent];
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
    
//    [NSUserDefaults standardUserDefaults].registeredDeviceToken = @"4";
}


#pragma mark - CLLocationManagerDelegate

- (void)updateTrackingStatus
{
    EventTimeProximity eventProximity = [self eventTimeProximity];
    
    if (eventProximity == EventTimeProximityAfter) {
        [NSUserDefaults standardUserDefaults].trackingUser = NO;
    }
    
    if (![NSUserDefaults standardUserDefaults].trackingUser) {
        [self.locationManager stopUpdatingLocation];
        _isTrackingLocationAccurately = NO;
        return;
    }
    
    BOOL isInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
    
    if (([self eventTimeProximity] == EventTimeProximitySoonBefore || [self eventTimeProximity] == EventTimeProximitySoonAfter) || !isInBackground) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager startUpdatingLocation];
        _isTrackingLocationAccurately = YES;
        
    } else {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
        _isTrackingLocationAccurately = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    BOOL isInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
        
    if (locations.count) {
        [self sendLocationUpdate:locations[locations.count - 1] isInBackground:isInBackground];
        if ([[NSUserDefaults standardUserDefaults].lastEventUpdate timeIntervalSinceNow] < -60) {
            [self updateEvent];
        }
    };
}

- (void)sendLocationUpdate:(CLLocation *)location isInBackground:(BOOL)isInBackground
{
    if (isInBackground) {
        NSLog(@"Sending location update in background: %@", location);
        
        _backgroundLocationTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundLocationTask];
        }];
        
        if (!_isTrackingLocationAccurately && ([self eventTimeProximity] == EventTimeProximitySoonBefore || [self eventTimeProximity] == EventTimeProximitySoonAfter)) {
            [self updateTrackingStatus];
        }
        
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


#pragma mark - Private

- (EventTimeProximity)eventTimeProximity
{
    NSDate *date = [NSUserDefaults standardUserDefaults].eventDate;
    
    if (!date) return EventTimeProximityAfter;
    
    NSTimeInterval secondsSinceEvent = [[NSDate date] timeIntervalSinceDate:date];
    
    BOOL isCloseToEventTime = fabs(secondsSinceEvent) < EventSecondsProximity;

    if (secondsSinceEvent <= 0) {
        return isCloseToEventTime ? EventTimeProximitySoonBefore : EventTimeProximityBefore;
    
    } else {
        return isCloseToEventTime ? EventTimeProximitySoonAfter : EventTimeProximityAfter;
    }
}

 - (void)updateEvent
{
    if (_isUpdatingEvent) return;
    
    _isUpdatingEvent = YES;
    
    [HRDAPI retrieveEventWithCompletion:^(HRDAnnotation *eventAnnotation, NSDate *eventDate, NSError *error) {
        _isUpdatingEvent = NO;
        
        if (error) {
            NSLog(@"ERROR retrieveing event: %@",error);
            return;
        }
        
        [NSUserDefaults standardUserDefaults].eventDate = eventDate;
        [NSUserDefaults standardUserDefaults].lastEventUpdate = [NSDate date];
        
        if (self.viewController.meetingPointAnnotation.coordinate.latitude != eventAnnotation.coordinate.latitude ||
            self.viewController.meetingPointAnnotation.coordinate.longitude != eventAnnotation.coordinate.longitude) {
            self.viewController.meetingPointAnnotation = eventAnnotation;
        }
        [(HRDAppDelegate *)[UIApplication sharedApplication].delegate updateTrackingStatus];
    }];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

@end
