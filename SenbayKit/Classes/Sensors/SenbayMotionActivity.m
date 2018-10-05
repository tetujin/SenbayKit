//
//  SenbayMotionActivity.m
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/12.
//

#import "SenbayMotionActivity.h"

@implementation SenbayMotionActivity{
    NSString * value;
}

- (instancetype) init
{
    self = [super init];
    if (self!=nil) {
        _motionActivityManager = [[CMMotionActivityManager alloc] init];
        value = @"";
    }
    return self;
}

- (BOOL)activate
{
    if (![CMMotionActivityManager isActivityAvailable]) {
        return NO;
    } else {
        [_motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue]
                                   withHandler:^(CMMotionActivity *activity) {
                                       NSMutableString * mactivites = [[NSMutableString alloc] init];
                                       
                                       if(activity.stationary) [mactivites appendString:@"stationary|"];
                                       if(activity.walking)    [mactivites appendString:@"walking|"];
                                       if(activity.running)    [mactivites appendString:@"running|"];
                                       if(activity.unknown)    [mactivites appendString:@"unknown|"];
                                       if(activity.cycling)    [mactivites appendString:@"cycling|"];
                                       if(activity.automotive) [mactivites appendString:@"automotive|"];
                                       
                                       if (mactivites.length > 0) {
                                           [mactivites deleteCharactersInRange:NSMakeRange(mactivites.length-1, 1)];
                                           self->value = mactivites;
                                       }
                                   }];
        return YES;
    }
}

- (BOOL)deactivate
{
    if (![CMMotionActivityManager isActivityAvailable]) {
        return NO;
    } else {
        [_motionActivityManager stopActivityUpdates];
        return YES;
    }
}

- (NSString *)getData
{
    if ([value isEqualToString:@""]) {
        return nil;
    }else{
        return [NSString stringWithFormat:@"MACT:'%@'",value];
    }
}

@end
