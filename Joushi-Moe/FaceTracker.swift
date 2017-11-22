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
    let videoLayer : AVCaptureVideoPreviewLayer
    let replicatorLayer: CAReplicatorLayer = CAReplicatorLayer()

    let view: UIView
    var replicateCount: Int
    let findface: (_ arr:Array<CGRect>) -> Void
    var currentVideoOrientation: AVCaptureVideoOrientation?

    enum Mode: Int {
        case Camera = 1
        case VR = 2
    }

    required init(view: UIView, replicateCount: Int, findface: @escaping (_ arr:Array<CGRect>) -> Void) {
        self.view=view
        self.replicateCount = replicateCount
        self.findface = findface
        self.videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)

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

        videoLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / CGFloat(replicateCount))
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        replicatorLayer.addSublayer(videoLayer)
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0, view.bounds.height / CGFloat(replicateCount), 0)
        replicatorLayer.instanceCount = replicateCount
        replicatorLayer.instanceDelay = 0
        view.layer.addSublayer(replicatorLayer)
        
        
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
    
    func changeMode(mode: Mode) {
        switch mode {
        case .Camera:
            replicateCount = 1
        case .VR:
            replicateCount = 2
        }
        
        videoLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / CGFloat(replicateCount))
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0, view.bounds.height / CGFloat(replicateCount), 0)
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
        let image: UIImage = UIImage(cgImage: imageRef!)
        return image
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        //同期処理（非同期処理ではキューが溜まりすぎて画面がついていかない）
        DispatchQueue.main.sync(execute: {
            
            //バッファーをUIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            let ciimage:CIImage! = CIImage(image: image)
            
            //CIDetectorAccuracyHighだと高精度（使った感じは遠距離による判定の精度）だが処理が遅くなる
            let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorTracking] )!

            let options = [CIDetectorImageOrientation : exifOrientation(orientation: UIDevice.current.orientation)]
            let faces = detector.features(in: ciimage, options: options) as NSArray
            
            var rects = Array<CGRect>();
            if faces.count != 0 {
                var _ : CIFaceFeature = CIFaceFeature()
                for feature in faces {
                    
                    // 座標変換
                    var faceRect : CGRect = (feature as AnyObject).bounds
                    let per = (self.view.bounds.width/image.size.width)
                    
                    // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
                    faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                    
                    //倍率変換
                    faceRect.origin.x = faceRect.origin.x * per
                    if replicateCount == 1 {
                        faceRect.origin.y = faceRect.origin.y * per
                    } else {
                        faceRect.origin.y = faceRect.origin.y * per - self.view.bounds.height / 4
                    }
                    faceRect.size.width = faceRect.size.width * per
                    faceRect.size.height = faceRect.size.height * per
                    
                    rects.append(faceRect)
                }
            }
            
            self.findface(rects)
        })
    }

    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
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
