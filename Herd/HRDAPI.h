//
//  HRDAPI.h
//  Herd
//
//  Created by Bryan Hansen on 1/6/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "HRDAnnotation.h"

@interface HRDAPI : NSObject

+ (void)retrieveAllUserAnnotationsWithCompletion:(void(^)(NSArray *userAnnotations, NSError *error))completionBlock;

+ (void)updateUserWithLocation:(CLLocationCoordinate2D)coordinate;

@end
