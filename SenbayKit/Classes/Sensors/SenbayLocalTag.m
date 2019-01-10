//
//  SenbayLocalTag.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/10/09.
//

#import "SenbayLocalTag.h"

@implementation SenbayLocalTag
{
    BOOL isActive;
    NSString * localTag;
}

- (void) setLocalTag:(NSString *)tag{
    localTag = [[NSString alloc] initWithString:tag];
}

- (void) activate
{
    isActive = YES;
}

- (void) deactivate
{
    isActive = NO;
}

- (NSString *)getData
{
    if (isActive) {
        if (localTag != nil) {
            return [NSString stringWithFormat:@"LTAG:'%@'",localTag];
        }
    }
    return nil;
}

@end
