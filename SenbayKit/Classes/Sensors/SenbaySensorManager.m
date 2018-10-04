//
//  SenbaySensorManager.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/14.
//

#import "SenbaySensorManager.h"
#import "SenbayFormat.h"

@implementation SenbaySensorManager{
    SenbayFormat * format ;
    BOOL isFreeFormat;
    NSString * freeFormatData;
}

- (instancetype)init
{
    self = [super init];
    if (self!=nil) {
        format          = [[SenbayFormat alloc] init];
        _baseNumber     = 122;
        _sensors        = [[NSMutableArray alloc] init];
        _imu            = [[SenbayIMU alloc] init];
        _location       = [[SenbayLocation alloc] init];
        _motionActivity = [[SenbayMotionActivity alloc] init];
        _ble            = [[SenbayBLE alloc] init];
        _screenBrightness = [[SenbayScreenBrightness alloc] init];
        _networkSocket  = [[SenbayNetworkSocket alloc] init];
        _batteryLevel   = [[SenbayBattery alloc] init];
        _weather        = [[SenbayOpenWeatherMap alloc] init];
        [_sensors addObjectsFromArray:@[_imu,_location,_motionActivity,_ble,_screenBrightness,_networkSocket,_batteryLevel,_weather]];
    }
    return self;
}

- (NSString *)getFormattedData
{
    NSMutableString * line = [[NSMutableString alloc] init];
    
    [line appendFormat:@"TIME:%f,",[NSDate new].timeIntervalSince1970];
    
    for (SenbaySensor * sensor in _sensors) {
        NSString * data = [sensor getData];
        // NSLog(@"[%@] %@", NSStringFromClass([sensor class]), data);
        if (data != nil && ![data isEqualToString:@""]){
            [line appendFormat:@"%@,",data];
        }
    }
    
    NSRange lastCharacter = NSMakeRange(line.length-1, 1);
    [line deleteCharactersInRange:lastCharacter];
    
    if (isFreeFormat) {
        if (freeFormatData != nil) {
            return self->freeFormatData;
        }
    }
    
    if (_doCompression) {
        NSMutableString * encodedString = [[NSMutableString alloc] initWithString:[format encode:line baseNumber:_baseNumber]];
        [encodedString insertString:@"V:4," atIndex:0];
        return encodedString;
    } else {
        [line insertString:@"V:3," atIndex:0];
        return line;
    }
}

- (void)useFreeFormatData:(BOOL)isFreeFormat
{
    self->isFreeFormat = isFreeFormat;
}

- (void)setFreeFormatData:(NSString *)freeFormatData
{
    self->freeFormatData = freeFormatData;
}


@end
