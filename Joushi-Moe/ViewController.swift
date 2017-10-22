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
    @IBOutlet var mode: UISegmentedControl!
    
    var faceTracker: FaceTracker? = nil
    var voiceChanger: VoiceChanger? = nil
    var replicateCount: Int = 2
    var failedCount: Int = 0
    var maxFailedCount: Int = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        faceTracker = FaceTracker(view: self.cameraView, replicateCount: replicateCount, findface:findface)
        voiceChanger = VoiceChanger()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    var imageView1 = UIImageView(image: #imageLiteral(resourceName: "moe"))
    var imageView2 = UIImageView(image: #imageLiteral(resourceName: "moe"))
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.imageView1.alpha = 0
        self.imageView2.alpha = 0
        self.view.addSubview(self.imageView1)
        self.view.addSubview(self.imageView2)

        faceTracker?.start()
        voiceChanger?.start()
    }

    
    func findface(_ arr:Array<CGRect>) -> Void {
        guard arr.count > 0 else {
            failedCount = failedCount + 1
            if maxFailedCount < failedCount {
                self.imageView1.alpha = 0
                self.imageView2.alpha = 0
            }
            return
        }
        
        let rect = arr[0] //一番の顔だけ使う
        let imageRect = rect * 2.0
        guard imageRect.origin.y + imageRect.height < self.view.frame.height / CGFloat(replicateCount), 0 < imageRect.origin.y else {
            failedCount = failedCount + 1
            if maxFailedCount < failedCount {
                self.imageView1.alpha = 0
                self.imageView2.alpha = 0
            }
            return
        }
        
        failedCount = 0
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            imageView1.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            imageView2.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        case .landscapeLeft:
            imageView1.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            imageView2.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        case .landscapeRight:
            imageView1.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2) * 3)
            imageView2.transform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2) * 3)
        default:
            imageView1.transform = CGAffineTransform(rotationAngle: 0)
            imageView2.transform = CGAffineTransform(rotationAngle: 0)
        }
        
        self.imageView1.frame = imageRect
        self.imageView2.frame = imageRect
        self.imageView2.frame.origin.y = self.imageView2.frame.origin.y + self.view.frame.height / CGFloat(replicateCount)
        
        self.imageView1.alpha = 1
        
        if replicateCount == 2 {
            self.imageView2.alpha = 1
        }
    }
    
    @IBAction func changeMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            replicateCount = 1
        case 1:
            replicateCount = 2
        default:
            replicateCount = 1
        }
        
        faceTracker?.changeMode(mode: FaceTracker.Mode(rawValue: replicateCount)!)
    }
}
