//
//  SenbayReaderViewController.h
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/04.
//  Copyright © 2018 tetujin. All rights reserved.
//

#import <UIKit/UIKit.h>
@import SenbayKit;

NS_ASSUME_NONNULL_BEGIN

@interface SenbayReaderViewController : UIViewController <SenbayReaderDelegate>
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UILabel *rawDataLabel;
- (IBAction)pushedCloseButton:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
