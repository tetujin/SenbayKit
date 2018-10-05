//
//  SenbayCameraSwiftViewController.swift
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/05.
//  Copyright © 2018 tetujin. All rights reserved.
//

import UIKit
import SenbayKit

class SenbayCameraSwiftViewController: UIViewController, SenbayCameraDelegate {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var timeLabel:    UILabel!
    @IBOutlet weak var fpsLabel:     UILabel!
    @IBOutlet weak var rawDataLabel: UILabel!

    var camera: SenbayCamera!
    
    var isRecording: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = SenbayCamera.init(previewView: previewImageView)
        camera.activate()
        camera.delegate = self;
        isRecording = false
        if let location = camera.sensorManager.location {
            location.activateGPS()
            location.activateSpeedometer()
        }
        if let imu = camera.sensorManager.imu{
            imu.activateAccelerometer()
        }
        if let weather = camera.sensorManager.weather{
            weather.activate()
        }
        
    }
    
    @IBAction func pushedCaptureButton(_ sender: UIButton) {
        if isRecording {
            camera.stopRecording()
            isRecording = false
            captureButton.setTitle("Start", for: .normal)
        }else{
            camera.startRecording()
            isRecording = true
            captureButton.setTitle("Stop", for: .normal)
        }
    }
    
    @IBAction func pushedCloseButton(_ sender: UIButton) {
        if isRecording {
            camera.stopRecording()
            isRecording = false
            captureButton.setTitle("Start", for: .normal)
        }
        self.dismiss(animated: true) {
            
        }
    }
    
    func didUpdateCurrentFPS(_ currentFPS: Int32) {
        fpsLabel.text = String(currentFPS) + "FPS"
    }
    
    func didUpdateFormattedRecordTime(_ recordTime: String!) {
        timeLabel.text = recordTime
    }
    
    func didUpdateQRCodeContent(_ qrcodeContent: String!) {
        rawDataLabel.text = qrcodeContent
    }
    
    

    override var shouldAutorotate: Bool {
        return  false
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
