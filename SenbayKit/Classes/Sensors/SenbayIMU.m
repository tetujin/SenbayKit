//
//  SenbayIMU.m
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/11.
//

#import "SenbayIMU.h"

@implementation SenbayIMU
{
    BOOL isAccelerometerActive;
    BOOL isGyroscopeActive;
    BOOL isMagnetometerActive;
    
    // accelerometer
    NSString * keyAccX;
    NSString * keyAccY;
    NSString * keyAccZ;
    // gyroscope
    NSString * keyGyroX;
    NSString * keyGyroY;
    NSString * keyGyroZ;
    // magnetometer
    NSString * keyMagX;
    NSString * keyMagY;
    NSString * keyMagZ;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.accelerometerUpdateInterval = 1.0/60.0;
        _motionManager.gyroUpdateInterval          = 1.0/60.0;
        _motionManager.magnetometerUpdateInterval  = 1.0/60.0;
        keyAccX  = @"ACCX";
        keyAccY  = @"ACCY";
        keyAccZ  = @"ACCZ";
        keyGyroX = @"PITC";
        keyGyroY = @"ROLL";
        keyGyroZ = @"YAW";
        keyMagX  = @"MAGX";
        keyMagY  = @"MAGY";
        keyMagZ  = @"MAGZ";
    }
    return self;
}

///////////////////////////////
- (BOOL)activateAccelerometer
{
    if (![_motionManager isAccelerometerAvailable]) {
        return NO;
    }
    [_motionManager startAccelerometerUpdates];
    isAccelerometerActive = YES;
    
    return YES;
}

- (BOOL)deactivateAccelerometer
{
    isAccelerometerActive = NO;
    if (![_motionManager isAccelerometerAvailable]) {
        return NO;
    }else{
        [_motionManager stopAccelerometerUpdates];
    }
    return YES;
}

/////////////////////////////////
- (BOOL)activateGyroscope
{
    /* *
     The three possible angles (see above) are called:
     
     Pitch: A pitch is a rotation around a lateral (X) axis that passes through the device from side to side
     Roll: A roll is a rotation around a longitudinal (Y) axis that passes through the device from its top to bottom
     Yaw: A yaw is a rotation around an axis (Z) that runs vertically through the device. It is perpendicular to the body of the device, with its origin at the center of gravity and directed toward the bottom of the device
     */
    if (![_motionManager isGyroAvailable]) {
        return NO;
    }
    
    [_motionManager startGyroUpdates];
    isGyroscopeActive = YES;
    return YES;
}

- (BOOL)deactivateGyroscope
{
    isGyroscopeActive = NO;
    if (![_motionManager isGyroAvailable]) {
        return NO;
    }else{
        [_motionManager stopGyroUpdates];
    }
    return YES;
}

///////////////////////////////
- (BOOL)activateMagnetometer
{
    if (![_motionManager isMagnetometerAvailable]) {
        return NO;
    }
    
    [_motionManager startMagnetometerUpdates];
    isMagnetometerActive = YES;
    return YES;
}

- (BOOL)deactivateMagnetometer
{
    isMagnetometerActive = NO;
    if (![_motionManager isMagnetometerAvailable]) {
        return NO;
    }else{
        [_motionManager stopMagnetometerUpdates];
    }
    return YES;
}

///////////////////////////////
- (NSString *)getData
{
    NSMutableString * data = [[NSMutableString alloc] init];

    if (isAccelerometerActive) {
        [data appendFormat:@"%@:%f,%@:%f,%@:%f,",
         keyAccX,_motionManager.accelerometerData.acceleration.x,
         keyAccY,_motionManager.accelerometerData.acceleration.y,
         keyAccZ,_motionManager.accelerometerData.acceleration.z];
    }
    
    if (isGyroscopeActive) {
        [data appendFormat:@"%@:%f,%@:%f,%@:%f,",
         keyGyroX,_motionManager.gyroData.rotationRate.x,
         keyGyroY,_motionManager.gyroData.rotationRate.y,
         keyGyroZ,_motionManager.gyroData.rotationRate.z];
    }
    
    if (isMagnetometerActive) {
        [data appendFormat:@"%@:%f,%@:%f,%@:%f,",
         keyMagX,_motionManager.magnetometerData.magneticField.x,
         keyMagY,_motionManager.magnetometerData.magneticField.y,
         keyMagZ,_motionManager.magnetometerData.magneticField.z];
    }

    if (data.length > 0) {
        [data deleteCharactersInRange:NSMakeRange(data.length-1, 1)];
    }
    
    return data;
}

@end
