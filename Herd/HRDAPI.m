//
//  HRDAPI.m
//  Herd
//
//  Created by Bryan Hansen on 1/6/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import "HRDAPI.h"
#import "NSUserDefaults+Herd.h"

static NSString * const APIDomain = @"http://mighty-lake-3989.herokuapp.com/";

@implementation HRDAPI

+ (void)retrieveAllUserAnnotationsWithCompletion:(void(^)(NSArray *userAnnotations, NSError *error))completionBlock;
{
    NSString *urlString = [APIDomain stringByAppendingPathComponent:@"location"];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            completionBlock(nil,error);
            return;
        }
        
        NSError *parsingError = nil;
        NSArray *userDicts = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parsingError];
        
        if (parsingError) {
            completionBlock(nil,parsingError);
            return;
        }
        
        NSMutableArray *allAnnotations = [NSMutableArray arrayWithCapacity:userDicts.count];
        
        [userDicts enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSDictionary *userInfo, NSUInteger idx, BOOL *stop) {
            NSString *deviceToken = [userInfo objectForKey:@"deviceToken"];
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[userInfo objectForKey:@"latitude"] doubleValue], [[userInfo objectForKey:@"longitude"] doubleValue]);
            NSString *name = [userInfo objectForKey:@"username"];
            BOOL hasArrived = [[userInfo objectForKey:@"has_arrived"] boolValue];
            
            HRDAnnotation *annotation = [[HRDAnnotation alloc] initWithUUID:deviceToken coordinate:coordinate title:name hasArrived:hasArrived];
            
            [allAnnotations addObject:annotation];
        }];
        
        completionBlock(allAnnotations, nil);
    }];    
}

+ (void)updateUserWithLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [APIDomain stringByAppendingPathComponent:@"location"];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    //2013-01-06T11:46:10Z
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    
    NSDictionary *parameters = @{@"username" : [NSUserDefaults standardUserDefaults].username,
                                 @"deviceToken" : [NSUserDefaults standardUserDefaults].registeredDeviceToken,
                                 @"latitude" : [NSNumber numberWithDouble:coordinate.latitude],
                                 @"longitude" : [NSNumber numberWithDouble:coordinate.longitude]
    };
    
    NSError *jsonError = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    request.HTTPBody = postData;

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error updating user location: %@",error);
            
        } else if (((NSHTTPURLResponse *)response).statusCode >= 400) {
            NSLog(@"Response error when updating user location: %d",((NSHTTPURLResponse *)response).statusCode);
        }
    }];
}


@end
