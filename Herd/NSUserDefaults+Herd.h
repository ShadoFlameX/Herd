//
//  NSUserDefaults+Herd.h
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (Herd)

@property (copy, nonatomic) NSString *registeredDeviceToken;
@property (copy, nonatomic) NSString *username;
@property (assign) BOOL trackingUser;
@property (strong, nonatomic) NSDate *eventDate;

@end
