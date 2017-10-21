//
//  VoiceChanger.swift
//  Joushi-Moe
//
//  Created by zizi on 2017/10/21.
//  Copyright © 2017年 zizi. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation

class VoiceChanger: NSObject {
    var engine: AVAudioEngine!
    var player: AVAudioPlayerNode!
    
    var file = AVAudioFile()
    
    func start() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        player.volume = 1.0
        
        let path = Bundle.main.path(forResource: "muon_10sec", ofType: "wav")!
        let url = NSURL.fileURL(withPath: path)
        
        let file = try? AVAudioFile(forReading: url)
        let buffer = AVAudioPCMBuffer(pcmFormat: file!.processingFormat, frameCapacity: AVAudioFrameCount(file!.length))
        do {
            try file!.read(into: buffer)
        } catch _ {
        }
        
        let pitch = AVAudioUnitTimePitch()
        
        //
        pitch.pitch = -500 //Distortion
        pitch.rate = 1.5 //Voice speed
        //
        
        engine.attach(player)
        
        engine.attach(pitch)
        
        engine.connect(player, to: pitch, format: buffer.format)
        
        engine.connect(pitch, to: engine.mainMixerNode, format: buffer.format)
        player.scheduleBuffer(buffer, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
        
        engine.prepare()
        do {
            try engine.start()
        } catch _ {
        }
        
        player.play()
    }
}
