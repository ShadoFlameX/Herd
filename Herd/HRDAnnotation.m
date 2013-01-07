//
//  HRDAnnotation.m
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import "HRDAnnotation.h"

@interface HRDAnnotation ()

@property (copy, nonatomic, readwrite) NSString *uuid;

@end

@implementation HRDAnnotation

- (id)initWithUUID:(NSString *)uuid coordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title hasArrived:(BOOL)hasArrived
{
    self = [super init];
    if (self) {
        self.uuid = uuid;
        self.coordinate = coordinate;
        self.title = title;
        self.hasArrived = hasArrived;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - title: %@, uuid: %@, lat: %f, long: %f, hasArrived: %d",super.description, self.title, self.uuid, self.coordinate.latitude, self.coordinate.longitude, self.hasArrived];
}

@end
