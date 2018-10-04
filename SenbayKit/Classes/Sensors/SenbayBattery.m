//
//  SenbayBattery.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import "SenbayBattery.h"

@implementation SenbayBattery
{
    BOOL isBatteryActive;
}

- (void)activate
{
    isBatteryActive = YES;
}

- (void)deactivate
{
    isBatteryActive = NO;
}

- (NSString *)getDate
{
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    if (isBatteryActive) {
        return [NSString stringWithFormat:@"BATT:%f",batteryLevel];
    }
    return nil; //BATT
}


@end
