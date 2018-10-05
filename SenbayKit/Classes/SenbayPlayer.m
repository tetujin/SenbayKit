//
//  SenbayPlayer.m
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import "SenbayPlayer.h"

@implementation SenbayPlayer
{
    SenbayData * senbayData;
    NSTimer    * timer;
    CIDetector * detector;
}

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if(self!= nil){
        _view      = view;
        senbayData = [[SenbayData alloc] init];
        detector   = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    }
    return self;
}

- (void)setupPlayerWithLoadedAsset:(AVAsset *)asset
{
    NSDictionary* settings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    self.playerOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self.playerItem addOutput:self.playerOutput];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    playerLayer.frame = self.view.frame;
    [_view.layer addSublayer:playerLayer];
}

- (BOOL) play {
    if (_player == nil) {
        return NO;
    }
    [_player play];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0f target:self selector:@selector(getVideoFrame) userInfo:nil repeats:YES];
    return YES;
}

- (BOOL) pause {
    if (_player == nil) {
        return NO;
    }
    [_player pause];
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    return YES;
}

- (void)getVideoFrame
{
    if (_player != nil) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            @autoreleasepool{
                CVPixelBufferRef buffer = [self.playerOutput copyPixelBufferForItemTime:[self.playerItem currentTime] itemTimeForDisplay:nil];
                CIImage *image = [CIImage imageWithCVPixelBuffer:buffer];

                NSArray *features = [detector featuresInImage:image];
                
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

                    NSDictionary * data = [senbayData decodeFormattedData:qrcodeContent];
                    if ([self.delegate respondsToSelector:@selector(didDecodeQRcode:)]) {
                        [self.delegate didDecodeQRcode:data];
                    }
                }
                CVPixelBufferRelease(buffer);
            }
        }
    }
}

@end
