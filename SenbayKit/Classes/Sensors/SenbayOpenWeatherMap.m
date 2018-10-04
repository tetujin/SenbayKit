//
//  SenbayOpenWeatherMap.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/22.
//

#import "SenbayOpenWeatherMap.h"

@implementation SenbayOpenWeatherMap{
    bool isOWMActive;
    NSTimer * timer;
    OpenWeatherModel * owModel;
    NSString * latestData;
}

- (instancetype)init
{
    self = [super init];
    if (self!=nil) {
        isOWMActive = NO;
        _updateInterval = 60 * 10; // every 10 min
        owModel = [[OpenWeatherModel alloc] init];
    }
    return self;
}

- (void)activate
{
    if (!isOWMActive) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        [self checkLocationServicesAndStartUpdates];
        [_locationManager startUpdatingLocation];
        isOWMActive = YES;
        
        timer = [NSTimer scheduledTimerWithTimeInterval:_updateInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
            CLLocation * location = self->_locationManager.location;
            if (location!=nil) {
                [self updateLocation:location];
            }
        }];
    }
}

- (void) updateLocation:(CLLocation *)location
{
    NSLog(@"[weather] sent a HTTP request for updating weather info");
    [self->owModel updateWeatherWithLat:location.coordinate.latitude
                                    lon:location.coordinate.longitude
                                 hadler:^(NSDictionary * _Nullable resultDict,
                                          NSData * _Nullable resultData,
                                          NSError * _Nullable error) {
                                     NSMutableString * data = [[NSMutableString alloc] init];
                                     if (error==nil && self->owModel!=nil) {
                                         if ([self->owModel getTemperature] != nil) {
                                             [data appendFormat:@"TEMP:%@,",[self->owModel getTemperature]];
                                         }
                                         if ([self->owModel getWeather] != nil) {
                                             [data appendFormat:@"WEAT:'%@',",[self->owModel getWeather]];
                                         }
                                         if ([self->owModel getHumidity] != nil) {
                                             [data appendFormat:@"HUMI:%@,",[self->owModel getHumidity]];
                                         }
                                         if ([self->owModel getWindSpeed]) {
                                             [data appendFormat:@"WIND:%@,",[self->owModel getWindSpeed]];
                                         }
                                         if (data.length > 0) {
                                             [data deleteCharactersInRange:NSMakeRange(data.length-1, 1)];
                                         }
                                         self->latestData = data;
                                     }
                                 }];
}

- (void)deactivate
{
    if (isOWMActive) {
        isOWMActive = NO;
        [_locationManager stopUpdatingLocation];
        _locationManager = nil;
        if (timer!=nil) {
            [timer invalidate];
            timer = nil;
        }
    }
}

- (NSString *)getData
{
    if (isOWMActive) {
        return latestData;
    }else{
        return nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    if (locations != nil && locations.count > 0) {
        CLLocation * location = [locations lastObject];
        if (latestData == nil) {
            [self updateLocation:location];
        }
    }
}

//////////////////////////////////////////////
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
