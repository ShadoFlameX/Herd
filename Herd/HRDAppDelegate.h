//
//  HRDAppDelegate.h
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class HRDMapViewController;

@interface HRDAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HRDMapViewController *viewController;
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;

- (void)updateTrackingStatus;

@end
