//
//  SenbaySensorManager.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/14.
//

#import <Foundation/Foundation.h>
#import "SenbaySensor.h"
// sensors
#import "SenbayIMU.h"
#import "SenbayLocation.h"
#import "SenbayMotionActivity.h"
#import "SenbayBLE.h"
#import "SenbayBattery.h"
#import "SenbayNetworkSocket.h"
#import "SenbayScreenBrightness.h"
#import "SenbayOpenWeatherMap.h"
#import "SenbayLocalTag.h"

@interface SenbaySensorManager : NSObject

@property BOOL doCompression;
@property int  baseNumber;

@property NSMutableArray       * sensors;

//////// defualt sensors ////////////
/// IMU: accelerometer, gyroscope, magneticfield
@property (readonly) SenbayIMU            * imu;
/// Location: GPS, speed, barometer, direction(heading)
@property (readonly) SenbayLocation       * location;
/// Motion Activity: stationary, walking, and running ... etc
@property (readonly) SenbayMotionActivity * motionActivity;
/// WebAPI: OpenWeather API
@property (readonly) SenbayOpenWeatherMap * weather;

// Screen
@property (readonly) SenbayScreenBrightness * screenBrightness;
// Battery
@property (readonly) SenbayBattery          * batteryLevel;
/// BLE: SensorTag, HR, (JINS MEME), External
@property (readonly) SenbayBLE              * ble;
/// Datagram Socket
@property (readonly) SenbayNetworkSocket    * networkSocket;
/// Local Tag
@property (readonly) SenbayLocalTag         * tag;

- (void) useFreeFormatData:(BOOL) isFreeFormat;
- (void) setFreeFormatData:(NSString *) freeFormatData;

- (NSString *) getFormattedData;

@end
