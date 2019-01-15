//
//  SenbayReaderSwiftViewController.swift
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/05.
//  Copyright © 2018 tetujin. All rights reserved.
//

import UIKit
import SenbayKit

class SenbayReaderSwiftViewController: UIViewController, SenbayReaderDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var rawDataLabel: UILabel!
    
    var reader:SenbayReader!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reader = SenbayReader()
        // Do any additional setup after loading the view.
        reader.delegate = self;
        reader.startCameraReader(withPreviewView: previewView)
    }
    
    func didDetectQRcode(_ qrcode: String!) {
        rawDataLabel.text = qrcode
    }
    
    func didDecodeQRcode(_ senbayData: [String : NSObject]!) {
        
    }
    
    @IBAction func pushedCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    override var shouldAutorotate: Bool{
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .portrait
    }
    
}
