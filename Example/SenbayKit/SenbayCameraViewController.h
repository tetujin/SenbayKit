//
//  SenbayCameraViewController.h
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/03.
//  Copyright © 2018 tetujin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SenbayKit/SenbayCamera.h>

NS_ASSUME_NONNULL_BEGIN

@interface SenbayCameraViewController : UIViewController <SenbayCameraDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
- (IBAction)pushedCaptureButton:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;

- (IBAction)pushedCloseButton:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *rawDataLabel;

@end

NS_ASSUME_NONNULL_END
