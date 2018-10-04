//
//  SenbayPlayer.h
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import <Foundation/Foundation.h>
#import "SenbayReader.h"
#import "SenbayData.h"
@import AVFoundation;
@import UIKit;

@protocol SenbayPlayerDelegate <NSObject>
@optional
- (void) didDetectQRcode:(NSString *) qrcode;
- (void) didDecodeQRcode:(NSDictionary *) senbayData;
@end


@interface SenbayPlayer : NSObject<SenbayPlayerDelegate>

@property (weak, nonatomic) id <SenbayPlayerDelegate> delegate;

@property (strong, nonatomic) UIView    * view;
@property (strong, nonatomic) AVPlayer  * player;
@property (strong, nonatomic) AVPlayerItem * playerItem;
@property (strong, nonatomic) AVPlayerItemVideoOutput *playerOutput;

- (instancetype)initWithView:(UIView *)view;
- (void)setupPlayerWithLoadedAsset:(AVAsset *)asset;

@end
