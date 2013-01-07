//
//  HRDAnnotation.h
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface HRDAnnotation : NSObject <MKAnnotation>

@property (copy, nonatomic, readonly) NSString *uuid;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (nonatomic) BOOL hasArrived;

- (id)initWithUUID:(NSString *)uuid coordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title hasArrived:(BOOL)hasArrived;

@end
