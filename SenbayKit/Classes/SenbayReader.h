//
//  SenbayReader.h
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/PHPhotoLibrary.h>
#import <Photos/PHAssetChangeRequest.h>
#import <CoreMedia/CoreMedia.h>

@protocol SenbayReaderDelegate <NSObject>
@optional
- (void) didDetectQRcode:(NSString *) qrcode;
- (void) didDecodeQRcode:(NSDictionary <NSString *, NSObject *> *) senbayData;
@end

@interface SenbayReader : NSObject <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property (weak, nonatomic) id <SenbayReaderDelegate> delegate;
@property (strong, nonatomic) AVCaptureSession *session;

- (void) startCameraReaderWithPreviewView:(UIView *) previewView;
- (void) stopCameraReader;

- (void) startScreenReader;
- (void) stopScreenReader;

@end
