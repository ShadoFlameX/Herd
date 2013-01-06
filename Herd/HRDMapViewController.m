//
//  HRDViewController.m
//  Herd
//
//  Created by Bryan Hansen on 1/3/13.
//  Copyright (c) 2013 Bryan Hansen. All rights reserved.
//

#import "HRDMapViewController.h"
#import "HRDAnnotation.h"
#import "HRDAPI.h"
#import "NSUserDefaults+Herd.h"
#import "HRDGeoMath.h"
#import "HRDAppDelegate.h"
#import <MapKit/MapKit.h>

static CGFloat const DefaultMapSpan = 0.5f;

@interface HRDMapViewController ()

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UISwitch *trackingSwitch;
@property (strong, nonatomic) HRDAnnotation *meetingPointAnnotation;
@property (strong, nonatomic) NSMutableDictionary *otherUserAnnotations;

@end

@implementation HRDMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.otherUserAnnotations = [NSMutableDictionary dictionary];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.79118f, -122.401519);
	
    self.meetingPointAnnotation = [[HRDAnnotation alloc] initWithUUID:nil coordinate:coordinate title:@"SeatMe HQ"];
    
    [self.mapView addAnnotation:self.meetingPointAnnotation];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.meetingPointAnnotation.coordinate, convertMilesToMeters(DefaultMapSpan), (DefaultMapSpan));
    
    self.mapView.region = region;
    
    self.mapView.showsUserLocation = YES;
    
    self.nameTextField.text = [NSUserDefaults standardUserDefaults].username;
    self.trackingSwitch.on = [NSUserDefaults standardUserDefaults].trackingUser;    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateUserLocations];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions

- (IBAction)saveName:(id)sender
{
    [NSUserDefaults standardUserDefaults].username = self.nameTextField.text;
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.nameTextField resignFirstResponder];
}

- (IBAction)toggleTracking:(id)sender
{
    if (![NSUserDefaults standardUserDefaults].username.length) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Please Save Your Name" message:@"You must save a name before enabling user tracking" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [self.trackingSwitch setOn:NO animated:YES];
        [NSUserDefaults standardUserDefaults].trackingUser = NO;
        [self.nameTextField becomeFirstResponder];
        
        return;
    }
    
    BOOL isTracking = self.trackingSwitch.on;
    
    [NSUserDefaults standardUserDefaults].trackingUser = isTracking;
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    HRDAppDelegate *appDelegate = (HRDAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [NSUserDefaults standardUserDefaults].eventDate = isTracking ? [self nextEventDate] : nil;
    [appDelegate updateTrackingStatus];
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[HRDAnnotation class]]) {
        return nil;
    }
    
    MKAnnotationView *annotationView = nil;
    
    if ([annotation isEqual:self.meetingPointAnnotation]) {
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"MeetingPoint"];
        
        if (!annotationView) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MeetingPoint"];
        }

    } else {
        annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"Person"];
        
        if (!annotationView) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Person"];
            annotationView.image = [UIImage imageNamed:@"person"];
            annotationView.calloutOffset = CGPointMake(0.0f, 0.0f);
        }
    }
    
    annotationView.annotation = annotation;
    annotationView.canShowCallout = YES;
    
    return annotationView;
}


#pragma mark - Private

- (void)updateUserLocations
{
    [HRDAPI retrieveAllUserAnnotationsWithCompletion:^(NSArray *userAnnotations, NSError *error) {
        if (error) {
            NSLog(@"Error loading all users: %@",error);
            return;
        }
        
        NSMutableArray *annotationsToRemove = [self.otherUserAnnotations.allValues mutableCopy];
        
        [userAnnotations enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HRDAnnotation *annotation, NSUInteger idx, BOOL *stop) {
            if ([annotation.uuid isEqualToString:[NSUserDefaults standardUserDefaults].registeredDeviceToken]) return;
            
            if ([self.otherUserAnnotations.allKeys containsObject:annotation.uuid]) {
                HRDAnnotation *existingAnnotation = [self.otherUserAnnotations valueForKey:annotation.uuid];
                existingAnnotation.coordinate = annotation.coordinate;
                existingAnnotation.title = annotation.title;
                
                [annotationsToRemove removeObject:existingAnnotation];

            } else {
                
                [self.otherUserAnnotations setObject:annotation forKey:annotation.uuid];
                [self.mapView addAnnotation:annotation];
            }            
        }];
        
        for (HRDAnnotation *oldAnnotation in annotationsToRemove) {
            [self.mapView removeAnnotation:oldAnnotation];
            [self.otherUserAnnotations removeObjectForKey:oldAnnotation.uuid];
        }
        
        [self performSelector:@selector(updateUserLocations) withObject:nil afterDelay:2.0f];
    }];
}


#pragma mark - Private

- (NSDate *)nextEventDate
{
    NSDateComponents *eventDateComponents = [[NSDateComponents alloc] init];
    eventDateComponents.hour = 10;
    eventDateComponents.minute = 10;
    eventDateComponents.second = 0;

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    
    NSDateComponents *nextEventComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                         fromDate:now];
    
    nextEventComponents.hour = eventDateComponents.hour;
    nextEventComponents.minute = eventDateComponents.hour;
    nextEventComponents.second = eventDateComponents.hour;
    
    NSDate *nextEventDate = [calendar dateFromComponents:nextEventComponents];

    NSTimeInterval delta = [nextEventDate timeIntervalSinceDate:now];
    
    if (delta < 1.0f) {
        nextEventComponents.day += 1;
        nextEventDate = [calendar dateFromComponents:nextEventComponents];
    }
    
    return nextEventDate;
}

@end