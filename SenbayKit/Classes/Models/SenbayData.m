//
//  SenbayData.m
//  GSCall
//
//  Created by Yuuki Nishiyama on 2018/06/28.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//

#import "SenbayData.h"
#import "SenbayFormat.h"

@implementation SenbayData
{
    SenbayFormat * format;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        format          = [[SenbayFormat alloc] init];
        _baseNumber     = 122;
    }
    return self;
}


- (NSDictionary *)decodeFormattedData:(NSString *)data
{
    // Senbay Format を判定
    if([data hasPrefix:@"T"] || [data hasPrefix:@"0"] || [data hasPrefix:@"V"]){
        NSString *decodedStr = @"";
        // データの圧縮が行われている場合は、圧縮を解除する
        if([data hasPrefix:@"V"]){ // Version 3 or 4
            NSArray* array = [data componentsSeparatedByString:@","];
            NSArray* content = [[array objectAtIndex:0] componentsSeparatedByString:@":"];
            NSString* version = [content objectAtIndex:1];
            if ([version isEqualToString:@"3"]){ //圧縮無しの場合
                // NSLog(@"no compression (version 3)");
                decodedStr = data;
            }else if([version isEqualToString:@"4"]){ //圧縮ありの場合
                // NSLog(@"compression (version 4)");
                decodedStr = [format decode:data baseNumber:_baseNumber];
            }else{
                NSLog(@"This is unsupported version of QR-code format!!");
            }
        }else if([data hasPrefix:@"0"]){//圧縮ありの場合
            // NSLog(@"compression (version 2)");
            decodedStr = [format decode:data baseNumber:_baseNumber];
        }else{ //圧縮無しの場合
            // NSLog(@"compression (version 1)");
            decodedStr = data;
        }
        
        // 圧縮解除後の文字列を解析して、辞書型オブジェクトに返信して返す
        if (decodedStr != nil) {
            NSMutableDictionary * senbayData = [[NSMutableDictionary alloc] init];
            NSArray * elements = [decodedStr componentsSeparatedByString:@","];
            for (NSString * element in elements) {
                NSArray * keyValue = [element componentsSeparatedByString:@":"];
                if (keyValue != nil && keyValue.count > 1) {
                    NSString * key = keyValue[0];
                    NSString * strValue = keyValue[1];
                    NSNumber * numValue = nil;
                    if (key.length > 0) {
                        if ([strValue hasPrefix:@"'"]) { // string
                            NSMutableString * mString = [[NSMutableString alloc] initWithString:strValue];
                            [mString deleteCharactersInRange:NSMakeRange(0, 1)];
                            [mString deleteCharactersInRange:NSMakeRange(mString.length-1, 1)];
                            strValue = mString;
                        }else if([strValue hasPrefix:@"-"] ||
                                 [strValue hasPrefix:@"0"] ||
                                 [strValue hasPrefix:@"1"] ||
                                 [strValue hasPrefix:@"2"] ||
                                 [strValue hasPrefix:@"3"] ||
                                 [strValue hasPrefix:@"4"] ||
                                 [strValue hasPrefix:@"5"] ||
                                 [strValue hasPrefix:@"6"] ||
                                 [strValue hasPrefix:@"7"] ||
                                 [strValue hasPrefix:@"8"] ||
                                 [strValue hasPrefix:@"9"]   ){ // number
                            NSArray * dot = [strValue componentsSeparatedByString:@"."];
                            if (dot.count > 1) { // double
                                numValue = @(strValue.doubleValue);
                            }else{ // int
                                numValue = @(strValue.intValue);
                            }
                        }
                    }
                    
                    if (numValue==nil) {
                        [senbayData setObject:strValue forKey:key];
                    }else{
                        [senbayData setObject:numValue forKey:key];
                    }
                    
                }
            }
            return senbayData;
        }
    }
    return nil;
}


@end
