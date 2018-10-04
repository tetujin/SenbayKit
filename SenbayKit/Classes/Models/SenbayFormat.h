//
//  CompressQRCordFormat.h
//  SpecialNumber
//
//  Created by Yuuki Nishiyama on 2014/12/08.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SenbayFormat : NSObject
- (NSString *) encode:(NSString *)text baseNumber:(int)baseNumber;
- (NSString *) decode:(NSString *)text baseNumber:(int)baseNumber;
@end
