//
//  SpeechRecognizerViewModel.swift
//  ios
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognizerViewModel: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))

    // 認識完了時のコールバック
    var onRecognitionCompleted: ((String) -> Void)?

    // 権限チェック
    func checkPermissions() async -> Bool {
        // 音声認識権限のチェック
        let speechStatus = await requestSpeechRecognitionAuthorization()
        guard speechStatus else {
            errorMessage = "音声認識の権限が必要です"
            return false
        }

        // マイク権限のチェック
        let micStatus = await requestMicrophoneAuthorization()
        guard micStatus else {
            errorMessage = "マイクの権限が必要です"
            return false
        }

        return true
    }

    private func requestSpeechRecognitionAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    // 録音開始
    func startRecording() async {
        // 既存のタスクをキャンセル
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // 権限チェック
        guard await checkPermissions() else {
            return
        }

        // オーディオセッション設定
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "オーディオセッションの設定に失敗しました: \(error.localizedDescription)"
            return
        }

        // オーディオエンジンの初期化
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode

        // 認識リクエストの作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        // 認識タスクの開始
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                Task { @MainActor in
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            }
        }

        // オーディオバッファの設定
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // 録音開始
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            recognizedText = ""
            errorMessage = nil
        } catch {
            errorMessage = "録音の開始に失敗しました: \(error.localizedDescription)"
        }
    }

    // 録音停止
    func stopRecording() {
        audioEngine?.stop()
        recognitionRequest?.endAudio()

        isRecording = false

        // 認識結果をログに出力
        if !recognizedText.isEmpty {
            print("認識されたテキスト: \(recognizedText)")

            // コールバックを呼び出し
            onRecognitionCompleted?(recognizedText)
        }
    }
}
