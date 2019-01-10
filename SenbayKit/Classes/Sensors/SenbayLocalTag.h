//
//  SenbayLocalTag.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/10/09.
//

#import <Foundation/Foundation.h>
#import "SenbaySensor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SenbayLocalTag : SenbaySensor

- (void) setLocalTag:(NSString *)tag;
- (void) activate;
- (void) deactivate;

@end

NS_ASSUME_NONNULL_END
