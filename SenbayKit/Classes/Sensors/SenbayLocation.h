//
//  SenbayLocation.h
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/12.
//

#import <Foundation/Foundation.h>
#import "SenbaySensor.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface SenbayLocation : SenbaySensor <CLLocationManagerDelegate>

@property CLLocationManager * locationManager;
@property CMAltimeter * altimeter;

@property (readonly) BOOL isGPSActive;
@property (readonly) BOOL isCompassActive;
@property (readonly) BOOL isSpeedmeterActive;
@property (readonly) BOOL isBarometerActive;

- (void)activateGPS;
- (void)deactivateGPS;

- (void)activateCompass;
- (void)deactivateCompass;

- (void)activateSpeedometer;
- (void)deactivateSpeedometer;

- (void)activateBarometer;
- (void)deactivateBarometer;

@end
