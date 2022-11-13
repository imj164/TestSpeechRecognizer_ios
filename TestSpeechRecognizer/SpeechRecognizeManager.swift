//
//  SpeechRecognizeManager.swift
//  TestSpeechRecognizer
//
//  Created by Hiroshi IMAJO on 2022/11/12.
//

import Speech

final class SpeechRecognizeManager: NSObject, ObservableObject {
    // 認識結果テキスト
    @Published var text = "Push Start to Recognize Your Speech"
    // 音声認識が有効か
    @Published var available = false
    // 音声認識を実行中か
    @Published var running = false

    // 音声認識
    // private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    // private let recognizer = SFSpeechRecognizer(locale: .current)   // アプリがローカライズ対応している場合はこちら
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages.first!))   // アプリがローカライズ対応していない場合はこちら
    // 音声認識リクエスト
    private var request: SFSpeechAudioBufferRecognitionRequest? = nil
    // 音声認識タスク
    private var task: SFSpeechRecognitionTask? = nil
    // オーディオエンジン
    private let engine = AVAudioEngine()

    // イニシャライザ（デリゲートをセット）
    override init() {
        super.init()
        recognizer?.delegate = self
    }

    // 音声認識開始
    func start() {
        if !engine.isRunning {
            do {
                try exec()
                running = true
            } catch {
                running = false
            }
        }
    }

    // 音声認識停止
    func stop() {
        if engine.isRunning {
            engine.stop()
            request?.endAudio()
            running = false
        }
    }
    
    // 音声認識実行
    private func exec() throws {
        // タスクがあれば停止
        task?.cancel()
        task = nil

        // オーディオセッションを準備
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let input = engine.inputNode

        // リクエストを準備
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            print("CANNOT create speech recognize request")
            return
        }
        // 部分的な認識結果を有効に
        request.shouldReportPartialResults = true
        // デバイスでの認識を有効に（するとエラーで動かないので無効に）
        request.requiresOnDeviceRecognition = false
        
        // タスクを準備
        task = recognizer?.recognitionTask(with: request) { result, error in
            // 最終認識結果か
            var isFinal = false
            // 認識結果を更新（部分的な認識結果の場合もあるので）
            if let result = result {
                self.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            // 最終認識結果かエラーの場合、タスク終了
            if isFinal || error != nil {
                // オーディオエンジン停止
                self.engine.stop()
                input.removeTap(onBus: 0)
                self.request = nil
                self.task = nil
                self.running = false
                print("stopped: \(isFinal), \(String(describing: error))")
            }
        }
        
        // マイク入力を準備
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
            self.request?.append(buffer)
        }
        
        // オーディオエンジン開始
        text = "(please speak)"
        engine.prepare()
        try engine.start()
    }
}

// 音声認識デリゲート
extension SpeechRecognizeManager: SFSpeechRecognizerDelegate {
    // 音声認識が有効・無効になった場合
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        self.available = available
        print("available: \(available)")
    }
}
