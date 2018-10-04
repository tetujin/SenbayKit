//
//  SenbayPlayerViewController.h
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/04.
//  Copyright © 2018 tetujin. All rights reserved.
//

#import <UIKit/UIKit.h>
@import SenbayKit;

NS_ASSUME_NONNULL_BEGIN

@interface SenbayPlayerViewController : UIViewController <SenbayPlayerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
- (IBAction)pushedSelectVideoButton:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIView *playerView;
- (IBAction)pushedPlayButton:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UILabel *rawDataLabel;

- (IBAction)pushedStopButton:(UIButton *)sender;
- (IBAction)pushedCloseButton:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
