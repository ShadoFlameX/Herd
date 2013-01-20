//
//  NSUserDefaults+Herd.m
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import "NSUserDefaults+Herd.h"
#import <objc/runtime.h>

static NSString * const RegisteredPushTokenKey = @"registeredPushToken";
static NSString * const UsernameKey = @"username";
static NSString * const TrackingUserKey = @"trackingUser";
static NSString * const EventDateKey = @"eventDate";
static NSString * const LastEventUpdateKey = @"lastEventUpdate";

@implementation NSUserDefaults (Herd)

- (NSString *)registeredDeviceToken
{
    return [self stringForKey:RegisteredPushTokenKey];
}

- (void)setRegisteredDeviceToken:(NSString *)registeredDeviceToken
{
    if (registeredDeviceToken.length) {
        [self setObject:registeredDeviceToken forKey:RegisteredPushTokenKey];
    } else {
        [self removeObjectForKey:registeredDeviceToken];
    }
}

- (NSString *)username
{
    return [self stringForKey:UsernameKey];
}

- (void)setUsername:(NSString *)username
{
    if (username.length) {
        [self setObject:username forKey:UsernameKey];
    }
    else {
        [self removeObjectForKey:UsernameKey];
    }
}

- (BOOL)trackingUser {
    return [self boolForKey:TrackingUserKey];
}

- (void)setTrackingUser:(BOOL)trackingUser {
    [self setBool:trackingUser forKey:TrackingUserKey];
}

- (NSDate *)eventDate {
    return [self objectForKey:EventDateKey];
}

- (void)setEventDate:(NSDate *)eventDate
{
    if (eventDate) {
        [self setObject:eventDate forKey:EventDateKey];
    } else {
        [self removeObjectForKey:EventDateKey];
    }
}

- (NSDate *)lastEventUpdate {
    return [self objectForKey:LastEventUpdateKey];
}

- (void)setLastEventUpdate:(NSDate *)lastEventUpdate
{
    if (lastEventUpdate) {
        [self setObject:lastEventUpdate forKey:LastEventUpdateKey];
    } else {
        [self removeObjectForKey:LastEventUpdateKey];
    }
}

@end
