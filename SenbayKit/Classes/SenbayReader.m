//
//  SenbayReader.m
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import "SenbayReader.h"
#import "SenbayData.h"

@implementation SenbayReader
{
    SenbayData * senbayData;
    NSTimer    * screenScanTimer;
    CIDetector * detector;
    AVCaptureVideoDataOutput * videoDataOutput;
    CGRect lastQRCodeBounds;
    int    noQRcodeFrames;
    bool   existLastQRCodeBounds;
    double fpsTime;
    int    fps;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        noQRcodeFrames = 0;
        fps = 0;
        fpsTime = 0;
        senbayData = [[SenbayData alloc] init];
        detector   = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    }
    return self;
}

- (void) startCameraReaderWithPreviewView:(UIView *) previewView
{
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    [self.session addInput:input];
    
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:output];
    // QR code only
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    
    ////////////////////////////////////////
    // (6) Setup video&audio output
    NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings = settings;
    
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    
    [self.session addOutput:videoDataOutput];
    
    ///////////////////////////////  カメラの向きを設定  ///////////////////////////////
    AVCaptureConnection *videoConnection = nil;
    
    [self.session beginConfiguration];
    
    for (AVCaptureConnection *connection in [videoDataOutput connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
            }
        }
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    [self.session commitConfiguration];
    
    ///////////////////////////////
    
    [self.session startRunning];
    
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    
    preview.frame = previewView.bounds;
    preview.masksToBounds = YES;
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [previewView.layer addSublayer:preview];
    
}

- (void) stopCameraReader
{
    [self.session stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if( !CMSampleBufferDataIsReady(sampleBuffer) ){
        return;
    }
    [self processVideoSampleBuffer:sampleBuffer];
}


- (void )processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
    // CGImageRef clip = CGImageCreateWithImageInRect(image.CGImage,scaledRect);

    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];

    //NSLog(@"%f,%f",lastQRCodeBounds.origin.x, lastQRCodeBounds.origin.y);
    //if (existLastQRCodeBounds && noQRcodeFrames < 5) {
        // ciImage = [ciImage imageByCroppingToRect:lastQRCodeBounds];
        // NSLog(@"%d",noQRcodeFrames);
    //}else{
        // NSLog(@"%d",noQRcodeFrames);
    //}

    // metadataOutput.rectOfInterest = CGRect.init(x: 0.0, y: 0.2, width: 0.3, height: 0.6)
    NSArray *features = [self->detector featuresInImage:ciImage];
    if (features != nil) {
        //QRコードが読めなかった場合
        if (features.count == 0) {
            noQRcodeFrames += 1;
            return;
        }else{
            existLastQRCodeBounds = YES;
            noQRcodeFrames = 0;
        }
        CIQRCodeFeature * qrcode = [features objectAtIndex:0];
        // lastQRCodeBounds = qrcode.bounds;

        NSString * qrcodeContent = qrcode.messageString;
        NSDictionary * data = [self->senbayData decodeFormattedData:qrcodeContent];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(didDetectQRcode:)]) {
                [self.delegate didDetectQRcode:qrcodeContent];
            }
            
            if ([self.delegate respondsToSelector:@selector(didDecodeQRcode:)]) {
                [self.delegate didDecodeQRcode:data];
            }
        });

        double now = [NSDate new].timeIntervalSince1970;
        if (fpsTime == 0) {
            fpsTime = now;
        }
        if (now - fpsTime > 1) {
            // NSLog(@"FPS: %d",fps);
            fpsTime = now;
            fps = 0;
        }else{
            fps++;
        }

    }else{
        noQRcodeFrames += 1;
    }
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    //QRコードが読めなかった場合
    if (metadataObjects.count == 0) {
        return;
    }
    
//    // lastQRCodeBounds = ((AVMetadataMachineReadableCodeObject *)[metadataObjects objectAtIndex:0]).bounds;
//    NSString * qrcodeContent = [metadataObjects objectAtIndex:0];
//    if ([self.delegate respondsToSelector:@selector(didDetectQRcode:)]) {
//        [self.delegate didDetectQRcode:qrcodeContent];
//    }
//
//    NSDictionary * data = [senbayData decodeFormattedData:qrcodeContent];
//    if ([self.delegate respondsToSelector:@selector(didDecodeQRcode:)]) {
//        [self.delegate didDecodeQRcode:data];
//    }
//
//    double now = [NSDate new].timeIntervalSince1970;
//    if (fpsTime == 0) {
//        fpsTime = now;
//    }
//    if (now - fpsTime > 1) {
//        NSLog(@"FPS: %d",fps);
//        fpsTime = now;
//        fps = 0;
//    }else{
//        fps++;
//    }
}


/////////////////////////////////

- (void) startScreenReader
{
    screenScanTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
        @autoreleasepool{
            UIImage * screenshot = [self takeScreenshot];
            
            if (screenshot != nil) {
                CIImage * ciImage = [[CIImage alloc] initWithImage:screenshot];
                NSArray *features = [self->detector featuresInImage:ciImage];
                if (features != nil) {
                    //QRコードが読めなかった場合
                    if (features.count  == 0) {
                        return;
                    }
                    CIQRCodeFeature * qrcode = [features objectAtIndex:0];
                    NSString * qrcodeContent = qrcode.messageString;
                    if ([self.delegate respondsToSelector:@selector(didDetectQRcode:)]) {
                        [self.delegate didDetectQRcode:qrcodeContent];
                    }
                    
                    NSDictionary * data = [self->senbayData decodeFormattedData:qrcodeContent];
                    if ([self.delegate respondsToSelector:@selector(didDecodeQRcode:)]) {
                        [self.delegate didDecodeQRcode:data];
                    }
                }
            }
        }
    }];
}

- (void) stopScreenReader
{
    [screenScanTimer invalidate];
    screenScanTimer = nil;
}

- (UIImage *)takeScreenshot
{
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGSize imageSize = mainScreen.bounds.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (![window respondsToSelector:@selector(screen)] || window.screen == mainScreen) {
            CGContextSaveGState(context);
            
            CGContextTranslateCTM(context, window.center.x, window.center.y);
            CGContextConcatCTM(context, [window transform]);
            CGContextTranslateCTM(context,
                                  -window.bounds.size.width * window.layer.anchorPoint.x,
                                  -window.bounds.size.height * window.layer.anchorPoint.y);
            
            [window.layer.presentationLayer renderInContext:context];
            
            CGContextRestoreGState(context);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}


@end
