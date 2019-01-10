//
//  SenbayQRcode.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2019/01/10.
//

#import "SenbayQRcode.h"

@implementation SenbayQRcode

- (instancetype)init{
    self = [super init];
    if (self!=nil) {
        // background color = white;
        backgroundColorRed    = 255;
        backgroundColorGreen  = 255;
        backgroundColorBlue   = 255;
        
        // block color = black;
        blockColorRed   =   0;
        blockColorGreen =   0;
        blockColorBlue  =   0;
        
        // init a QR code generator
        qrCodeFilter  = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        [qrCodeFilter setDefaults];
        ciContext         = [CIContext contextWithOptions:nil];
    }
    return self;
}


- (void)setBackgroundColor:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    int r = components[0] * 255 ; // r
    int g = components[1] * 255 ; // g
    int b = components[2] * 255 ; // b
    [self setBackgroundColorWithRead:r green:g blue:b];
}

- (void)setBlockColor:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    int r = components[0] * 255 ; // r
    int g = components[1] * 255 ; // g
    int b = components[2] * 255 ; // b
    [self setBlockColorWithRead:r green:g blue:b];
}

- (void)setBackgroundColorWithRead:(int)r
                                   green:(int)g
                                    blue:(int)b
{
    backgroundColorRed = r;
    backgroundColorGreen = g;
    backgroundColorBlue = b;
}

- (void)setBlockColorWithRead:(int)r
                              green:(int)g
                               blue:(int)b
{
    blockColorRed = r;
    blockColorGreen = g;
    blockColorBlue = b;
}


- (BOOL) isWhite:(int)r
           green:(int)g
            blue:(int)b
{
    if (r==255 && g==255 && b==255){
        return YES;
    }else{
        return NO;
    }
}

- (BOOL) isBlack:(int)r
           green:(int)g
            blue:(int)b
{
    if (r==0 && g==0 && b==0){
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)isBackgroundColorWhite{
    return [self isWhite:backgroundColorRed green:backgroundColorRed blue:backgroundColorBlue];
}

- (BOOL)isBlockColorBlack{
    return [self isBlack:blockColorRed green:blockColorGreen blue:blockColorBlue];
}

///////

- (UIImage *) generateQRCodeImageWithText:(NSString *)text size:(float)size
{
    UIImage *image = nil;
    @autoreleasepool {
        // generate data for QR code
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        [qrCodeFilter setValue:data forKey:@"inputMessage"];
        [qrCodeFilter setValue:@"L" forKey:@"inputCorrectionLevel"];
        
        // L: 7%  -> 4,296 bytes
        // M: 15% -> 3,391 bytes
        // Q: 25% -> 2,420 bytes
        // H: 30% -> 1,852 bytes
        
        // convert CGImage to UIImage
        CIImage * qrcode = [qrCodeFilter outputImage];
        
        CGImageRef cgimg = [ciContext createCGImage:qrcode fromRect:[qrcode extent]];
        
        if (![self isBackgroundColorWhite] || ![self isBlockColorBlack]) {
            NSUInteger width            = CGImageGetWidth(cgimg);
            NSUInteger height           = CGImageGetHeight(cgimg);
            CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
            unsigned char *rawData      = malloc(height * width * 4);
            NSUInteger bytesPerPixel    = 4;
            NSUInteger bytesPerRow      = bytesPerPixel * width;
            NSUInteger bitsPerComponent = 8;
            CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgimg);
            CGContextRelease(context);
            
            // Now your rawData contains the image data in the RGBA8888 pixel format.
            int x = 0;
            int y = 0;
            for(x=0; x<width; x++){
                for(y=0; y<height; y++){
                    long long byteIndex = (bytesPerRow * x) + y * bytesPerPixel;
                    int r = rawData[byteIndex];
                    int g = rawData[byteIndex + 1];
                    int b = rawData[byteIndex + 2];
                    // int a = rawData[byteIndex + 3];
                    if(r==0 && g==0 && b==0){ // convert a black block
                        if (![self isBlockColorBlack]) {
                            rawData[byteIndex] = blockColorRed ; // r
                            rawData[byteIndex + 1] = blockColorGreen; // g
                            rawData[byteIndex + 2] = blockColorBlue ; // b
                            // rawData[byteIndex + 3] = components[3] * 255; // a
                        }
                    } else if(r==255 && g==255 && b==255){ // convert a white block
                        if(![self isBackgroundColorWhite]){
                            rawData[byteIndex] = backgroundColorRed ; // r
                            rawData[byteIndex + 1] = backgroundColorGreen; // g
                            rawData[byteIndex + 2] = backgroundColorBlue ; // b
                            // rawData[byteIndex + 3] = components[3] * 255; // a
                        }
                    }
                }
            }
            
            CGImageRelease(cgimg);
            
            // generate a new CGImage with the new raw data (new color)
            CGContextRef newcontext = CGBitmapContextCreate (rawData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
            CGImageRef imageRef = CGBitmapContextCreateImage(newcontext);
            CGContextRelease(newcontext);
            CGColorSpaceRelease(colorSpace);
            
            // generate a new NSImage using the CGImage
            image = [[UIImage alloc] initWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUp];
            CGImageRelease(imageRef);
            
            free(rawData);
        }else{
            // generate a UIImage using the CIImage
            image = [UIImage imageWithCGImage:cgimg scale:1.0f orientation:UIImageOrientationUp];
            CGImageRelease(cgimg);
        }
        
        // scale the generated QR code
        UIGraphicsBeginImageContext(CGSizeMake(size, size));
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationNone); // set an interpolation method
        [image drawInRect:CGRectMake(0, 0, size, size)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return image;
}

- (UIImage *) fillImage:(UIImage *)baseImage
              withColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 24, 24);
    
    UIImage *image = [baseImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    
    [color setFill];
    [image drawInRect:rect];
    
    UIImage *editedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return editedImage;
}

- (void)camouflageByBackgroundColorWithRead:(int)r green:(int)g blue:(int)b{
    
    double backgroundAvgColor = (r + g + b)/3;
    
    if (backgroundAvgColor > 127) {
        [self setBackgroundColorWithRead:r green:g blue:b];
        [self setBlockColorWithRead:0 green:0 blue:0];
    }else{
        [self setBackgroundColorWithRead:255 green:255 blue:255];
        [self setBlockColorWithRead:r green:g blue:b];
    }
}

@end
