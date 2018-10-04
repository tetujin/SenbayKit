//
//  ReservedKeys.h
//  SpecialNumber
//
//  Created by Yuuki Nishiyama on 2014/12/27.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReservedKeys : NSObject
{
    NSMutableDictionary *reservedKeyValue;
    NSMutableDictionary *reservedValueKey;
}

- (void) setKeyValue:(NSString *)key
                     value:(NSString *)value;
- (NSString *) getValueByKey:(NSString *)key;
- (NSString *) getKeyByValue:(NSString *)value;

@end
