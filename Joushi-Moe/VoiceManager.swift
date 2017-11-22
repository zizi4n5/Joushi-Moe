import AVFoundation
import Speech

class VoiceManager: NSObject {
    
    let session = AVAudioSession.sharedInstance()
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let inputNode: AVAudioInputNode
    let outputNode: AVAudioOutputNode
    
    let pitchNode = AVAudioUnitTimePitch()
    var format: AVAudioFormat
    let pcmBufferSize: AVAudioFrameCount = 1024
    
    let speechRecognizer: SFSpeechRecognizer! // 1インスタンスから同時に2個以上のrecognitionTaskを生成できない 'SFSpeechAudioBufferRecognitionRequest cannot be re-used'エラーが発生するので注意！！
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    var recognitionTask: SFSpeechRecognitionTask?
    var talker = AVSpeechSynthesizer()
    var recognitionTime: Date?
    
    var recognitionResult: ((SFSpeechRecognitionResult) -> Void)?
    
    func start() {
        engine.prepare()
        try! engine.start()
        player.play()
    }
    
    func stop() {
        engine.stop()
        player.stop()
    }
    
    init(locale: Locale) {
        
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        inputNode = engine.inputNode!
        outputNode = engine.outputNode
        format = inputNode.inputFormat(forBus: 0) // inputNodeのFormat（モノラル）を使用しないと出力時に片側からしか音が出ないので注意！！

        super.init()

        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! session.setMode(AVAudioSessionModeVoiceChat)
        try! session.setActive(true)
        
        engine.attach(pitchNode)
        engine.attach(player)
        
        engine.connect(player, to: pitchNode, format: format)
        engine.connect(pitchNode, to: outputNode, format: format)
        
        inputNode.installTap(onBus: 0, bufferSize: pcmBufferSize, format: format)
        { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            self.recognitionRequest?.append(buffer)
        }
        
        // 音声認識の初期化
        initRecognitionRequest()
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {_ in
            if let time = self.recognitionTime?.timeIntervalSinceNow, 2 < -time {
                // 無音時間が閾値以上の場合は会話が途切れたと判断する
                self.initRecognitionRequest()
            } else {
                // 音声認識の開始前、または無音時間が閾値未満の場合は会話が継続中と判断して何もしない
            }
        }
    }
    
    fileprivate func initRecognitionRequest() {
        recognitionTask?.finish() // ちゃんとfinishを実行しておかないと1分の制限に引っかかってしまうので注意！！
        recognitionRequest?.endAudio()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: recognitionResultHandler)

        recognitionTime = nil
    }
    
    fileprivate func recognitionResultHandler(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            self.recognitionResult?(result)
            self.recognitionTime = Date()
        } else {
            // 失敗の場合は何もしない
        }
    }
}

