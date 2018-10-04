//
//  SenbayData.h
//  GSCall
//
//  Created by Yuuki Nishiyama on 2018/06/28.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SenbayData : NSObject

@property BOOL doCompression;
@property int  baseNumber;

- (NSDictionary * _Nullable) decodeFormattedData:(NSString *)data;

@end
