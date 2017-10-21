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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var faceTracker:FaceTracker? = nil;
    @IBOutlet var cameraView :UIView!//viewController上に一つviewを敷いてそれと繋いでおく
    
    // 通知センターを作る
    let notification = NotificationCenter.default
    
    
    var imageView = UIImageView(image: #imageLiteral(resourceName: "moe"))
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.imageView.alpha = 0
        self.view.addSubview(self.imageView)
        
        faceTracker = FaceTracker(view: self.cameraView, findface:findface)
        VoiceChanger().start()
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
