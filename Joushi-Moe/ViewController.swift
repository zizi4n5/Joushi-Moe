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

    @IBOutlet var cameraView :UIView!//viewController上に一つviewを敷いてそれと繋いでおく
    
    var faceTracker: FaceTracker? = nil
    var voiceChanger: VoiceChanger? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        faceTracker = FaceTracker(view: self.cameraView, findface:findface)
        voiceChanger = VoiceChanger()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    var imageView = UIImageView(image: #imageLiteral(resourceName: "moe"))
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.imageView.alpha = 0
        self.view.addSubview(self.imageView)

        faceTracker?.start()
        voiceChanger?.start()
    }

    
    func findface(_ arr:Array<CGRect>) -> Void {
        guard arr.count > 0 else {
            self.imageView.alpha = 0
            return
        }
        
        let rect = arr[0] //一番の顔だけ使う
        self.imageView.frame = rect * 2.0
        self.imageView.alpha = 1
    }
}
