//
//  SenbayMotionActivity.h
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/12.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "SenbaySensor.h"

@interface SenbayMotionActivity : SenbaySensor

@property CMMotionActivityManager * motionActivityManager;

- (BOOL) activate;
- (BOOL) deactivate;

@end
