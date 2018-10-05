//
//  SenbayPlayerSwiftViewController.swift
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/05.
//  Copyright © 2018 tetujin. All rights reserved.
//

import UIKit
import SenbayKit

class SenbayPlayerSwiftViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SenbayPlayerDelegate {

    @IBOutlet weak var playerView: UIView!
    
    var player: SenbayPlayer!
    
    @IBOutlet weak var rawDataLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player = SenbayPlayer.init(view: playerView)
        // Do any additional setup after loading the view.
        player.delegate = self;
    }
    
    @IBAction func pushedSelectButton(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            let cameraPicker = UIImagePickerController()
            cameraPicker.mediaTypes = ["public.movie"]
            cameraPicker.videoQuality = .typeHigh
            cameraPicker.modalPresentationStyle = .currentContext
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        let asset = AVAsset.init(url: videoURL!)
        if let unwrappedPlayer = player {
            unwrappedPlayer.setupPlayer(withLoadedAsset: asset)
        }
        picker .dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pushedPlayButton(_ sender: UIButton) {
        if let unwrappedPlayer = player {
            if(unwrappedPlayer.play()){
                print("play video")
            }else{
                print("error at pushedPlayButton")
            }
        }
    }
    
    @IBAction func pushedStopButton(_ sender: UIButton) {
        if let unwrappedPlayer = player {
            if(unwrappedPlayer.pause()){
                print("stop video")
            }else{
                print("error at pushedStopButton()")
            }
        }
    }
    
    @IBAction func pushedCloseButton(_ sender: UIButton) {
        pushedStopButton(sender)
        self.dismiss(animated: true) {}
    }
    
    func didDetectQRcode(_ qrcode: String!) {
        rawDataLabel.text = qrcode
    }
    
    override var shouldAutorotate: Bool{
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .landscapeRight
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
