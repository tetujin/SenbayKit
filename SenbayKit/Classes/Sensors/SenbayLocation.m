//
//  SenbayLocation.m
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/12.
//

#import "SenbayLocation.h"

@implementation SenbayLocation {
    CMAltitudeData * altitudeData;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil){
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        // locationManager.distanceFilter = 1.0f;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        _altimeter = [[CMAltimeter alloc] init];
    }
    return self;
}

//////////////////////

- (void)activateGPS
{
    [self checkLocationServicesAndStartUpdates];
    [_locationManager startUpdatingLocation];
    _isGPSActive = YES;
}

- (void)deactivateGPS
{
    _isGPSActive = NO;
    [_locationManager stopUpdatingLocation];
}

///////////////////////
- (void)activateSpeedometer
{
    _isSpeedmeterActive = YES;
}


- (void)deactivateSpeedometer
{
    _isSpeedmeterActive = NO;
}

///////////////////////

- (void)activateCompass
{
    [self checkLocationServicesAndStartUpdates];
    [_locationManager startUpdatingHeading];
    _isCompassActive = YES;
}

- (void)deactivateCompass
{
    _isCompassActive = NO;
    [_locationManager stopUpdatingHeading];
}

////////////////////////
- (void)activateBarometer
{
    [_altimeter startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error) {
        self->altitudeData = altitudeData;
    }];
    _isBarometerActive = YES;
}

- (void)deactivateBarometer
{
    _isBarometerActive = NO;
    [_altimeter stopRelativeAltitudeUpdates];
}

- (NSString *)getData
{
    NSMutableString * data = [[NSMutableString alloc] init];
    
    CLLocation * location = [_locationManager location];
    if (_isGPSActive) {
        [data appendFormat:@"LONG:%f,LATI:%f,ALTI:%f,", location.coordinate.longitude,location.coordinate.latitude,location.altitude];
        // NSLog(@"%@",data);
        // TODO
        //    horizontalAccuracy => HACC
        //    verticalAccuracy   => VACC
    }
    
    if(_isCompassActive){
        // 0 - 359.9 degree
        if (_locationManager.heading != nil) {
            [data appendFormat:@"HEAD:%f,",_locationManager.heading.trueHeading];
        }
    }
    
    if (_isSpeedmeterActive) {
        [data appendFormat:@"SPEE:%f,",_locationManager.location.speed];
    }
    
    
    if (_isBarometerActive) {
        // hPa
        [data appendFormat:@"AIRP:%f,", altitudeData.pressure.doubleValue * 10];
    }
    
    if (data.length > 0) {
        [data deleteCharactersInRange:NSMakeRange(data.length-1, 1)];
    }
    
    return data;
}

-(void) checkLocationServicesAndStartUpdates
{
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]){
        [_locationManager requestWhenInUseAuthorization];
    }
    //Checking authorization status
    if (![CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
        return;
    } else {
        //Location Services Enabled, let's start location updates
        [_locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self checkLocationServicesAndStartUpdates];
}

@end
