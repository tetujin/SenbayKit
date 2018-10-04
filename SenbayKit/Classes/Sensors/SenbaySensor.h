//
//  SenbayDataSource.h
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/11.
//

#import <Foundation/Foundation.h>

@interface SenbaySensor : NSObject

/**
 * If the value is Double or Int, this method returns following value
 * e.g., ACC:123.456 or ACCX:123.456,ACCY:123,ACCZ:0.123
 *
 * If the value is String, this method returns as follows
 * e.g., TAG:"tag1"
 */
- (NSString  * _Nullable ) getData;

@end
