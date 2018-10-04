//
//  SenbayReaderViewController.m
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/04.
//  Copyright © 2018 tetujin. All rights reserved.
//

#import "SenbayReaderViewController.h"

@interface SenbayReaderViewController ()

@end

@implementation SenbayReaderViewController{
    SenbayReader * reader;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    reader = [[SenbayReader alloc] init];
    reader.delegate = self;
    
    [reader startCameraReaderWithPreviewView:_previewView];
}

- (void)didDetectQRcode:(NSString *)qrcode{
    // _rawDataLabel.text = qrcode;
}

- (void)didDecodeQRcode:(NSDictionary *)senbayData{
    
    if(senbayData != nil){
        NSMutableString * data = [[NSMutableString alloc] init];
        for (NSString * key in senbayData) {
            [data appendFormat:@"%@:%@,", key, [senbayData objectForKey:key]];
        }
        if (data.length > 0) {
            [data deleteCharactersInRange:NSMakeRange(data.length-1, 1)];
        }
        _rawDataLabel.text = data;
    }
}

- (IBAction)pushedCloseButton:(UIButton *)sender {
    [reader stopCameraReader];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//- (BOOL) shouldAutorotate {
//    return NO;
//}
//
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMask;
//}



@end
