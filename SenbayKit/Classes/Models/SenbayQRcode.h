//
//  SenbayQRcode.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2019/01/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SenbayQRcode : NSObject {
    
    int backgroundColorRed;
    int backgroundColorGreen;
    int backgroundColorBlue;
    
    int blockColorRed;
    int blockColorGreen;
    int blockColorBlue;
    
    // QR code generator and filter
    CIFilter  * qrCodeFilter;
    CIContext * ciContext;
}

- (void) setBackgroundColor:(UIColor *)color;
- (void) setBlockColor:(UIColor *)color;
- (void) setBackgroundColorWithRead:(int)r green:(int)g blue:(int)b;
- (void) setBlockColorWithRead:(int)r green:(int)g blue:(int)b;

- (BOOL) isWhite:(int)r
           green:(int)g
            blue:(int)b;

- (BOOL) isBlack:(int)r
           green:(int)g
            blue:(int)b;

- (BOOL) isBackgroundColorWhite;
- (BOOL) isBlockColorBlack;

- (UIImage *) generateQRCodeImageWithText:(NSString *)text size:(float)size;
- (UIImage *) fillImage:(UIImage *)baseImage withColor:(UIColor *)color;

- (void) camouflageByBackgroundColorWithRead:(int)r green:(int)g blue:(int)b;

@end

NS_ASSUME_NONNULL_END
