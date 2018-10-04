//
//  SpecialNumber.m
//  SpecialNumber
//
//  Created by Yuuki Nishiyama on 2014/12/07.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import "BaseX.h"
#import "stdio.h"

@implementation BaseX
{
    NSArray* TABLE;
    NSArray* REVERSE_TABLE;
    Byte* hoge;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initTable];
    }
    return self;
}

/**
 * -----------------------------------------------
 * Decode "long value" to "String Special Number"
 * -----------------------------------------------
 */
- (NSString *) encodeBaseX:(int)shinsu longValue:(long)value
{
    if(shinsu > [TABLE count] || shinsu < 10){
        NSLog(@"shinsu must be 2-%ld",[TABLE count]);
    }
    //マイナスの値の場合は、プラスに変換
    bool isNegative = (value < 0);
    if(isNegative){
        value *= -1;
    }
    //X進数変換を行う
    NSMutableArray* ketas = [[NSMutableArray alloc]init];
    if(value == 0){
        [ketas addObject:@0];
    }else{
        while (value > 0) {
//            NSLog(@"%ld / %d  = %ld ... %d", (long)value, shinsu, ((long)value/(int)shinsu), (int)fmod(value, shinsu));
            int amari = (int)fmod(value, shinsu);
            [ketas addObject:[TABLE objectAtIndex:amari]];
            value = ((long)value / (int)shinsu);
        }
    }
    /**
     * 0x31 -> 16進数表記の1 (ascii文字)
     * 49   -> 10進数表記の1 (ascii文字)
     */
    NSMutableString *muString = [NSMutableString string];
    for(NSNumber* number in ketas){
        char ellipsis = [number floatValue];
        //NSLog(@"%@", [NSString stringWithFormat:@"=> %@", number]);
        //NSLog(@"%@", [NSString stringWithFormat:@"=== %c === %@",ellipsis, number]);
        [muString insertString:[NSString stringWithFormat:@"%c",ellipsis] atIndex:0];
    }
    if(isNegative){
        [muString insertString:@"-" atIndex:0];
        return muString;
    }else{
        return muString;
    }
}


/**
 * -----------------------------------------------
 * Decode "double value" to "String Special Number"
 * -----------------------------------------------
 */
- (NSString *) encodeBaseX:(int)shinsu doubleValue:(double)value
{
    
    if(shinsu > [TABLE count] || shinsu < 10){
        NSLog(@"shinsu must be 2-%ld",[TABLE count]);
    }
    //マイナスの値の場合は、プラスに変換
    bool isNegative = (value < 0);
    if(isNegative){
        value *= -1;
    }
    
    // double -> string に変換の際に、余計な0を表示しないようにする処理
    NSString *valueStr = [NSString stringWithFormat:@"%f", value];
    //NSNumber* number = [[NSNumber alloc] initWithDouble:value];
    NSMutableString *str = [[NSMutableString alloc]initWithString:valueStr];
    for(long long i=[str length]-1; i>=0; i--){
        char zero = '0';
        if([str characterAtIndex:i] == zero){
            [str deleteCharactersInRange:NSMakeRange(i, 1)];
        }else if([str characterAtIndex:i] == '.'){
            [str deleteCharactersInRange:NSMakeRange(i, 1)];
            break;
        }else{
            break;
        }
    }
    valueStr = [[NSString alloc]initWithString:str];
    //整数部と小数部を分割
    NSArray* doubleValues = [[NSArray alloc] initWithArray:[valueStr componentsSeparatedByString:@"."]];
//    NSLog(@"----> %d", [[doubleValues objectAtIndex:0] longLongValue]);
//    NSLog(@"----> %d", [[doubleValues objectAtIndex:1] longLongValue]);
    
    //整数部の計算
    NSString *integerString = [self encodeBaseX:shinsu longValue:[[doubleValues objectAtIndex:0] longLongValue]];
    if([doubleValues count] == 1){
        if(isNegative){
            return [NSString stringWithFormat:@"-%@", integerString];
        }else{
            return integerString;
        }
    }
    if([[doubleValues objectAtIndex:0] longLongValue] == 0){
        integerString =  [self encodeBaseX:shinsu longValue:0];
    }
    
    /**
     * ここから下が小数点以下の計算
     */
    //小数部の計算
    NSString *doubleString = [self encodeBaseX:shinsu longValue:[[doubleValues objectAtIndex:1] longLongValue]];
    
    //ゼロの追加
    NSMutableString *zeros = [[NSMutableString alloc] init];
    NSString *doubleBaseStr = [doubleValues objectAtIndex:1];
    for(int i=0; i<doubleBaseStr.length; i++){
        if([[doubleBaseStr substringWithRange:NSMakeRange(i, 1)] compare :@"0"] == NSOrderedSame){
            char ellipsis = [[TABLE objectAtIndex:0] floatValue];
            NSString *zeroChar = [NSString stringWithFormat:@"%c",ellipsis];
            // NSLog(@"%C",ellipsis);
            //[zeros appendFormat:zeroChar];
            [zeros appendString:zeroChar];
        }else{
            break;
        }
    }
    if(isNegative){
        //NSLog(@"%@",[NSString stringWithFormat:@"-%@.%@%@", integerString, zeros, doubleString]);
//        NSLog(@"i: %@", integerString);
//        NSLog(@"z: %@", zeros);
//        NSLog(@"d: %@", doubleBaseStr);
//        NSLog(@"%@",[NSString stringWithFormat:@"-%@.%@%@", integerString, zeros, doubleString]);
        return [NSString stringWithFormat:@"-%@.%@%@", integerString, zeros, doubleString];
    }else{
        // NSLog(@"-- %@", [doubleValues objectAtIndex:0]);
        if([doubleValues count] > 0){
            //NSLog(@"-- %@", [doubleValues objectAtIndex:1]);
        }
//        NSLog(@"i: %@", integerString);
//        NSLog(@"z: %@", zeros);
//        NSLog(@"d: %@", doubleBaseStr);
//        NSLog(@"%@", [NSString stringWithFormat:@"%@.%@%@", integerString, zeros, doubleString]);
//        long syosu =  [self decodeLongBaseX:shinsu value:doubleString];
        //NSLog(@"---------------> %d",syosu);
        return [NSString stringWithFormat:@"%@.%@%@", integerString, zeros, doubleString];
    }
}



/**
 * ここから下はデコード処理
 */

/**
 * -----------------------------------------------
 * Encode "String Special Number" to "long value"
 * -----------------------------------------------
 */
- (long)decodeLongBaseX:(int)shinsu value:(NSString *)value
{
    if(shinsu > [TABLE count] || shinsu < 10){
        NSLog(@"shinsu must be 2-128");
    }
    BOOL isNegative = [value hasPrefix:@"-"];
    
    //文字列からByte列に変換する
    NSData *asciiData = [value dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSUInteger len = [asciiData length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [asciiData bytes], len);
    long theValue = 0; //最終的に算出される値
//    for (int i=len-1; i>=0; i--) {
//        // TODO ここが何かおかしい気がする
//        // [REVERSE_TABLE[byteData[i]]の値が"39"のはずが"18"になっている。。。
//        NSLog(@"%d -> [%d]", i, byteData[i]);
//        //  NSLog(@"%ld * %ld = %ld", (long)pow(shinsu, len-i-1), [REVERSE_TABLE[byteData[i]] longValue] , v);
//        long v = pow(shinsu, len-i-1) * [REVERSE_TABLE[byteData[i]] longValue];
//        theValue += v;
//    }
    for (long long i=len-1; i>=0; i--) {
//        NSLog(@"%d -> [%d]", i, byteData[i]);
        long v = pow(shinsu, len-i-1) * [REVERSE_TABLE[byteData[i]] longValue];
//        NSLog(@"%ld * %ld = %ld", (long)pow(shinsu, len-i-1), [REVERSE_TABLE[byteData[i]] longValue] , v);
        theValue += v;
        
    }
    
    if(isNegative){
        return theValue * -1;
    }else{
        return theValue;
    }
}



-( double) decodeDoubleBaseX:(int)shinsu value:(NSString *)valueStr
{
    if(shinsu > [TABLE count] || shinsu < 10){
        NSLog(@"shinsu must be 2-128");
    }
    BOOL isNegative = [valueStr hasPrefix:@"-"];
    //少数点を判定する
    NSArray* doubleValues = [[NSArray alloc] initWithArray:[valueStr componentsSeparatedByString:@"."]];
    //NSLog(@"----> %@", [doubleValues objectAtIndex:0]);
    //NSLog(@"----> %@", [doubleValues objectAtIndex:1]);

    if([doubleValues count] > 0){
        
        //整数部の計算
        long seisu = [self decodeLongBaseX:shinsu value:[doubleValues objectAtIndex:0]];
        if(seisu == 0){
            seisu = 0;
        }
        if([doubleValues count] == 1){
            return seisu;
        }
        
        //ゼロの追加
        NSMutableString *zeros = [[NSMutableString alloc] init];
        NSString *doubleBaseStr = [doubleValues objectAtIndex:1];
        for(int i=0; i<doubleBaseStr.length; i++){
            //NSString *zeroChar = [NSString stringWithFormat:@"%c",[TABLE objectAtIndex:0]];
            char ellipsis = [[TABLE objectAtIndex:0] floatValue];
            NSString *zeroChar = [NSString stringWithFormat:@"%c",ellipsis];
            //ゼロ文字列の生成
            if([[doubleBaseStr substringWithRange:NSMakeRange(i, 1)] compare:zeroChar] == NSOrderedSame){
                [zeros appendString:@"0"];
            }else{
                break;
            }
        }
        
        NSMutableString *baseShosu = [[NSMutableString alloc] initWithString:[doubleValues objectAtIndex:1]];
        for(int i=0; i<zeros.length; i++){
            [baseShosu deleteCharactersInRange:NSMakeRange(0, 1)];
        }
            
        //小数部の計算
        long syosu =  [self decodeLongBaseX:shinsu value:baseShosu];
        
        
        //NSLog(@"%@", zeros);
        if(isNegative && seisu >= 0){//-0.1みたいなとき、整数部が0に変換されるため、-の後付けが必要
            //NSLog(@"%f",[[NSString stringWithFormat:@"-%d.%@%d",seisu,zeros,syosu] doubleValue]);
            return [[NSString stringWithFormat:@"-%ld.%@%ld",seisu,zeros,syosu] doubleValue];
            //return Double.parseDouble("-"+Integer.toString(seisu)+"."+zeros+Integer.toString(syosu));
        }else{
            //NSLog(@"--> %d", syosu);
            //NSLog(@"%f", [[NSString stringWithFormat:@"%d.%@%d",seisu,zeros,syosu] doubleValue]);
            return [[NSString stringWithFormat:@"%ld.%@%ld",seisu,zeros,syosu] doubleValue];
            //return Double.parseDouble(Integer.toString(seisu)+"."+zeros+Integer.toString(syosu));
        }
    }else{
        return [self decodeLongBaseX:shinsu value:valueStr];
    }
}




- (void) initTable
    {
        TABLE = [[NSArray alloc] initWithObjects:
                      @1, @2, @3, @4,
                 @5,  @6, @7, @8, @9,
                 @10, @11, @12, @13, @14,
                 @15, @16, @17, @18, @19,
                 @20, @21, @22, @23, @24,
                 @25, @26, @27, @28, @29,
                 @30, @31, @32, @33, @34,
                 @35, @36, @37, @38,
                 @40, @41, @42, @43,
                           @47, @48, @49,
                 @50, @51, @52, @53, @54,
                 @55, @56, @57,      @59,
                 @60, @61, @62, @63, @64,
                 @65, @66, @67, @68, @69,
                 @70, @71, @72, @73, @74,
                 @75, @76, @77, @78, @79,
                 @80, @81, @82, @83, @84,
                 @85, @86, @87, @88, @89,
                 @90, @91, @92, @93, @94,
                 @95, @96, @97, @98, @99,
                 @100, @101, @102, @103, @104,
                 @105, @106, @107, @108, @109,
                 @110, @111, @112, @113, @114,
                 @115, @116, @117, @118, @119,
                 @120, @121, @122, @123, @124,
                 @125, @126, @127,
                 nil];
        
        REVERSE_TABLE =   [[NSArray alloc] initWithObjects:
                           @0, @0, @1, @2, @3,
                           @4, @5, @6, @7, @8,
                           @9, @10, @11, @12, @13,
                           @14, @15, @16, @17, @18,
                           @19, @20, @21, @22, @23,
                           @24, @25, @26, @27, @28,
                           @29, @30,@31, @32, @33,
                           @34, @35, @36, @37,@0,
                           @38, @39, @40, @41,@0,
                           @0, @0, @42,@43,@44,
                           @45, @46, @47, @48, @49,
                           @50, @51, @52,  @0,  @53,
                           @54, @55, @56, @57, @58,
                           @59, @60, @61, @62, @63,
                           @64, @65, @66, @67, @68,
                           @69, @70, @71, @72, @73,
                           @74, @75, @76, @77, @78,
                           @79, @80, @81, @82, @83,
                           @84, @85, @86, @87, @88,
                           @89, @90, @91, @92, @93,
                           @94, @95, @96, @97, @98,
                           @99, @100, @101, @102, @103,
                           @104, @105, @106, @107, @108,
                           @109, @110, @111, @112, @113,
                           @114, @115, @116, @117, @118,
                           @119, @120, @121,
                           nil];
        
}


@end
