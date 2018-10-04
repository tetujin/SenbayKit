//
//  SenbayPlayerViewController.m
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/04.
//  Copyright © 2018 tetujin. All rights reserved.
//

#import "SenbayPlayerViewController.h"

@interface SenbayPlayerViewController ()

@end

@implementation SenbayPlayerViewController{
    SenbayPlayer * player;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    player = [[SenbayPlayer alloc] initWithView:_playerView];
    player.delegate = self;
    
}

- (IBAction)pushedSelectVideoButton:(UIButton *)sender {
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    videoPicker.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:videoPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL *url = info[UIImagePickerControllerMediaURL];
    AVAsset * asset = [AVAsset assetWithURL:url];
    if (asset != nil) {
        [player setupPlayerWithLoadedAsset:asset];
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (IBAction)pushedPlayButton:(UIButton *)sender {
    [player.player play];
}

- (IBAction)pushedStopButton:(UIButton *)sender {
    [player.player pause];
}

- (IBAction)pushedCloseButton:(UIButton *)sender {
    [player.player pause];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didDetectQRcode:(NSString *)qrcode{
    _rawDataLabel.text = qrcode;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL) shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}



@end
