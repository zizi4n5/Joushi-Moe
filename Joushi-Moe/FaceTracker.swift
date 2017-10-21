//
//  FaceTracker.swift
//  Joushi-Moe
//
//  Created by zizi on 2017/10/21.
//  Copyright © 2017年 zizi. All rights reserved.
//

import UIKit
import AVFoundation

class FaceTracker: NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {

    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    let videoOutput = AVCaptureVideoDataOutput()

    let view:UIView
    let findface : (_ arr:Array<CGRect>) -> Void
    var currentVideoOrientation: AVCaptureVideoOrientation?


    required init(view:UIView, findface: @escaping (_ arr:Array<CGRect>) -> Void) {
        self.view=view
        self.findface = findface
        super.init()

        initialize()
    }


    func initialize() {

        let videoInput = try! AVCaptureDeviceInput(device: self.videoDevice) as AVCaptureDeviceInput
        let audioInput = try! AVCaptureDeviceInput(device: self.audioDevice) as AVCaptureInput
        captureSession.addInput(videoInput)
        captureSession.addInput(audioInput)

        let queue:DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        captureSession.addOutput(videoOutput)

        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(videoLayer)

        for connection in videoOutput.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.isVideoOrientationSupported {
                    conn.videoOrientation = .portrait
                }
            }
        }
    }

    func start() {
        self.captureSession.startRunning()
    }


    func stop() {
        captureSession.stopRunning()
    }


    func restart() {
        stop()
        start()
    }


    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        //バッファーをUIImageに変換
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context!.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        return resultImage
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        //同期処理（非同期処理ではキューが溜まりすぎて画面がついていかない）
        DispatchQueue.main.sync(execute: {
            
            //バッファーをUIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            let ciimage:CIImage! = CIImage(image: image)
            
            //CIDetectorAccuracyHighだと高精度（使った感じは遠距離による判定の精度）だが処理が遅くなる
            let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyLow] )!

            print("exifOrientation\(exifOrientation(orientation: UIDevice.current.orientation))")
            let options = [CIDetectorImageOrientation : exifOrientation(orientation: UIDevice.current.orientation)]
            let faces = detector.features(in: ciimage, options: options) as NSArray
            
            var rects = Array<CGRect>();
            if faces.count != 0 {
                var _ : CIFaceFeature = CIFaceFeature()
                for feature in faces {
                    
                    // 座標変換
                    var faceRect : CGRect = (feature as AnyObject).bounds
                    let widthPer = (self.view.bounds.width/image.size.width)
                    let heightPer = (self.view.bounds.height/image.size.height)
                    
                    // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
                    faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                    
                    //倍率変換
                    faceRect.origin.x = faceRect.origin.x * widthPer
                    faceRect.origin.y = faceRect.origin.y * heightPer
                    faceRect.size.width = faceRect.size.width * widthPer
                    faceRect.size.height = faceRect.size.height * heightPer
                    
                    rects.append(faceRect)
                }
            }
            
            self.findface(rects)
        })
    }

    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        print("UIDeviceOrientation:\(orientation.rawValue)")
        switch orientation {
        case .portraitUpsideDown:
            return 3
        case .landscapeLeft:
            return 8
        case .landscapeRight:
            return 6
        default:
            return 1
        }
    }
}
