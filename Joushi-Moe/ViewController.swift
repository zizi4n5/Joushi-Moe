//
//  ViewController.swift
//  Joushi-Moe
//
//  Created by zizi on 2017/10/21.
//  Copyright © 2017年 zizi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var cameraView: UIView!
    @IBOutlet var faceTrackerCameraView: UIView!
    @IBOutlet var faceTrackerVRLeftView: UIView!
    @IBOutlet var faceTrackerVRRightView: UIView!
    @IBOutlet var mode: UISegmentedControl!
    
    var faceTracker: FaceTracker? = nil
    var voiceChanger: VoiceChanger? = nil
    var replicateCount: Int = 2
    var failedCount: Int = 0
    var maxFailedCount: Int = 10

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        faceTracker = FaceTracker(view: self.cameraView, replicateCount: replicateCount, findface:findface)
//        voiceChanger = VoiceChanger()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    var imageCameraView = UIImageView(image: #imageLiteral(resourceName: "moe"))
    var imageVRLeftView = UIImageView(image: #imageLiteral(resourceName: "moe"))
    var imageVRRightView = UIImageView(image: #imageLiteral(resourceName: "moe"))
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.imageCameraView.alpha = 0
        self.imageVRLeftView.alpha = 0
        self.imageVRRightView.alpha = 0
        self.faceTrackerCameraView.addSubview(self.imageCameraView)
        self.faceTrackerVRLeftView.addSubview(self.imageVRLeftView)
        self.faceTrackerVRRightView.addSubview(self.imageVRRightView)

        faceTracker?.start()
//        voiceChanger?.start()
    }

    
    func findface(_ arr:Array<CGRect>) -> Void {
        guard arr.count > 0 else {
            failedCount = failedCount + 1
            if maxFailedCount < failedCount {
                self.imageCameraView.alpha = 0
                self.imageVRLeftView.alpha = 0
                self.imageVRRightView.alpha = 0
            }
            return
        }
        
        let rect = arr[0] //一番の顔だけ使う
        let imageRect = rect * 2.0
//        guard imageRect.origin.y + imageRect.height < self.view.frame.height / CGFloat(replicateCount), 0 < imageRect.origin.y else {
//            failedCount = failedCount + 1
//            if maxFailedCount < failedCount {
//                self.imageCameraView.alpha = 0
//                self.imageVRLeftView.alpha = 0
//                self.imageVRRightView.alpha = 0
//            }
//            return
//        }
        
        failedCount = 0
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            imageCameraView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            imageVRLeftView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            imageVRRightView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        case .landscapeLeft:
            imageCameraView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            imageVRLeftView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            imageVRRightView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        case .landscapeRight:
            imageCameraView.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2) * 3)
            imageVRLeftView.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2) * 3)
            imageVRRightView.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2) * 3)
        default:
            imageCameraView.transform = CGAffineTransform(rotationAngle: 0)
            imageVRLeftView.transform = CGAffineTransform(rotationAngle: 0)
            imageVRRightView.transform = CGAffineTransform(rotationAngle: 0)
        }
        
        self.imageCameraView.frame = imageRect
        self.imageVRLeftView.frame = imageRect
        self.imageVRRightView.frame = imageRect
        
        self.imageCameraView.alpha = 1
        self.imageVRLeftView.alpha = 1
        self.imageVRRightView.alpha = 1
    }
    
    @IBAction func changeMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            faceTrackerCameraView.isHidden = true
            faceTrackerVRLeftView.isHidden = false
            faceTrackerVRRightView.isHidden = false
            replicateCount = 2
        default:
            faceTrackerCameraView.isHidden = false
            faceTrackerVRLeftView.isHidden = true
            faceTrackerVRRightView.isHidden = true
            replicateCount = 1
        }
        
        faceTracker?.changeMode(mode: FaceTracker.Mode(rawValue: replicateCount)!)
    }
//    
//    func postLine() {
//        let urlString = "https://api.line.me/v2/bot/message/push"
//        
//        let request = NSMutableURLRequest(url: URL(string: urlString)!)
//        
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("Authorization", forHTTPHeaderField: "Bearer mD9fp/ICvWckzb/ELJYvgWH6e3RcovUKkIN09dELUv3VsgWx5A4uMMBT+C/HSYsIID/NtGsdPFOFfrfJtmBzRunx81CgHNM9uENu/93qSmFxzuSuY466zQ3BhjMyS89c7G3JMcawVLAwaac8YT5kDwdB04t89/1O/w1cDnyilFU=")
//        request.addValue("-d", forHTTPHeaderField: "Content-Type")
//        
//        
//        
//        let params:[String:Any] = [
//            "d": "bar",
//            "baz":[
//                "a": 1,
//                "b": 2,
//                "x": 3]
//        ]
//        
//        do{
//            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
//            
//            let task:URLSessionDataTask = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data,response,error) -> Void in
//                let resultData = String(data: data!, encoding: .utf8)!
//                print("result:\(resultData)")
//                print("response:\(response)")
//                
//            })
//            task.resume()
//        }catch{
//            print("Error:\(error)")
//            return
//        }
//    }
}
