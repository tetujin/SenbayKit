//
//  SenbayIMU.h
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/11.
//

#import "SenbaySensor.h"
#import <CoreMotion/CoreMotion.h>

@interface SenbayIMU : SenbaySensor

@property CMMotionManager * motionManager;

- (BOOL) activateAccelerometer;
- (BOOL) deactivateAccelerometer;

- (BOOL) activateGyroscope;
- (BOOL) deactivateGyroscope;

- (BOOL) activateMagnetometer;
- (BOOL) deactivateMagnetometer;

@end
