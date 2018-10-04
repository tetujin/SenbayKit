//
//  CompressQRCordFormat.m
//  SpecialNumber
//
//  Created by Yuuki Nishiyama on 2014/12/08.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import "SenbayFormat.h"
#import "ReservedKeys.h"
#import "BaseX.h"

@implementation SenbayFormat
{
    ReservedKeys *reservedKeys;
    BaseX* baseX;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        reservedKeys = [[ReservedKeys alloc]init];
        [self initKeyArray];
        baseX = [[BaseX alloc] init];
    }
    return self;
}

- (void) initKeyArray
{
    [reservedKeys setKeyValue:@"TIME" value:@"0"];
    [reservedKeys setKeyValue:@"LONG" value:@"1"];
    [reservedKeys setKeyValue:@"LATI" value:@"2"];
    [reservedKeys setKeyValue:@"ALTI" value:@"3"];
    [reservedKeys setKeyValue:@"ACCX" value:@"4"];
    [reservedKeys setKeyValue:@"ACCY" value:@"5"];
    [reservedKeys setKeyValue:@"ACCZ" value:@"6"];
    [reservedKeys setKeyValue:@"YAW"  value:@"7"];
    [reservedKeys setKeyValue:@"ROLL" value:@"8"];
    [reservedKeys setKeyValue:@"PITC" value:@"9"];
    [reservedKeys setKeyValue:@"HEAD" value:@"A"];
    [reservedKeys setKeyValue:@"SPEE" value:@"B"];
    [reservedKeys setKeyValue:@"BRIG" value:@"C"];
    [reservedKeys setKeyValue:@"AIRP" value:@"D"];
    [reservedKeys setKeyValue:@"HTBT" value:@"E"];
//    [reservedKeys setKeyValue:@"MSG" value:@"F"];
}


- (NSString *)encode:(NSString *)text
          baseNumber:(int)baseNumber
{
//    NSLog(@"--> %@", text);
    NSArray* array = [text componentsSeparatedByString:@","];
    NSMutableString* newText = [[NSMutableString alloc] init];
    for (int i=0; i<[array count]; i++) {
        NSArray* contents = [[array objectAtIndex:i] componentsSeparatedByString:@":"];
        NSString* key = [contents objectAtIndex:0];
        NSString* reservedKey = [reservedKeys getValueByKey:key];
        //NSLog(@"%@ -> key -> %@", key, reservedKey);
        //予約されているキーの判定、予約語の場合は、:を省略する
        bool unkonwnKey = NO;
        //if([reservedKey compare:@"(null)"]){
        //NSLog(@"%d", [reservedKey length]);
        if([reservedKey length] != 0){
            key = reservedKey;
            unkonwnKey = YES;
        }else{
            unkonwnKey = NO;
        }
        // NSLog(@"%d", unkonwnKey);
        // NSLog(@"--> %@", [contents description]);
        NSString* value = [contents objectAtIndex:1];
        // NSLog(@"--> %@",value);
        
        if([value hasPrefix:@"'"]){
            if(contents.count > 2){
                value = [NSString stringWithFormat:@"%@:%@",[contents objectAtIndex:1],[contents objectAtIndex:2]];
                //NSLog(@"--> %@",value);
            }
            if(unkonwnKey){
                [newText appendString:[NSString stringWithFormat:@"%@%@", key, value]];
            }else{
                [newText appendString:[NSString stringWithFormat:@"%@:%@", key, value]];
            }
        }else {
            if(unkonwnKey){
                [newText appendString:[NSString stringWithFormat:@"%@%@", key, [baseX encodeBaseX:baseNumber doubleValue:[value doubleValue]]]];
            }else{
                [newText appendString:[NSString stringWithFormat:@"%@:%@", key, [baseX encodeBaseX:baseNumber doubleValue:[value doubleValue]]]];
                //if([key isEqualToString:@"0"]){
//                    NSLog(@"--> %f --> %@ --> %f" , [value doubleValue], [xNumber encodeBaseX:baseNumber doubleValue:[value doubleValue]], [xNumber decodeDoubleBaseX:baseNumber value:[xNumber encodeBaseX:baseNumber doubleValue:[value doubleValue]]]);
                //}
            }
        }
        if(i != [array count]-1){
            [newText appendString:@","];
        }
    }
    return newText;
}



- (NSString *) decode:(NSString *)text
           baseNumber:(int)baseNumber
{
//    SpecialNumber2* xNumber = [[SpecialNumber2 alloc] init];
    NSArray* array = [text componentsSeparatedByString:@","];
    NSMutableString* newText = [[NSMutableString alloc] init];
    for (int i=0; i<[array count]; i++){
        //"key"と"value"を分ける
        NSString* line = [array objectAtIndex:i];
        NSString* key = @"";
        NSString* value = @"";
        //NSLog(@"%@",line);
        NSArray* contents = [line componentsSeparatedByString:@":"];
        //:を使って分割できた場合
        if([contents count] > 1){
            key = [contents objectAtIndex:0];
            value = [contents objectAtIndex:1];
            //:を使って分割出来なかった場合
        }else{
            key = [line substringWithRange:NSMakeRange(0, 1)];
            value = [line substringWithRange:NSMakeRange(1, [line length]-1)];
        }
        //予約キーに登録されている場合は、keyの値を更新する
        NSString* reservedKey = [reservedKeys getKeyByValue:key];
        //NSLog(@"----------> %@",reservedKey);
        if([reservedKey length] != 0){
            key = reservedKey;
        }
        
        if([value hasPrefix:@"'"]){
            [newText appendString:[NSString stringWithFormat:@"%@:%@", key, value]];
        }else {
            //NSNumber* number = [[NSNumber alloc] initWithDouble:[xNumber encodeDoubleBaseX:baseNumber value:value]];
            //double of long
            NSRange range = [value rangeOfString:@"."];
            if (range.location != NSNotFound) {
                //case of double
//                NSLog(@"----> %@", value);
                double doubleValue = [baseX decodeDoubleBaseX:baseNumber value:value];
//                NSLog(@"====> %f", doubleValue);
                [newText appendString:[NSString stringWithFormat:@"%@:%f", key, doubleValue]];
            } else {
                //case of long
                long longValue = [baseX decodeLongBaseX:baseNumber value:value];
                [newText appendString:[NSString stringWithFormat:@"%@:%ld", key, longValue]];
            }
        }
        if(i != [array count]-1){
            [newText appendString:@","];
        }
    }
    return newText;
}

@end
