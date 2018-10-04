//
//  SenbayScreenBrightness.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import "SenbayScreenBrightness.h"

@implementation SenbayScreenBrightness{
    BOOL isScreenBrightnessActive;
}

- (void) activate
{
    isScreenBrightnessActive = YES;
}

- (void) deactivate
{
    isScreenBrightnessActive = NO;
}

- (NSString *)getData
{
    if (isScreenBrightnessActive) {
        CGFloat brightness = [UIScreen mainScreen].brightness;
        return [NSString stringWithFormat:@"BRIG:%f",brightness];
    }
    return nil;
}

@end
