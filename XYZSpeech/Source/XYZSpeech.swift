//
//  SpeechToTextObject.swift
//  SpeechToText
//
//  Created by 张子豪 on 2018/8/16.
//  Copyright © 2018年 zhangqian. All rights reserved.
//

import UIKit
import Speech
//import SoHow


public class XYZSpeech: NSObject,SFSpeechRecognizerDelegate {
    static var currentSTT : XYZSpeech?
    
 
    //调整语言
    
    static var SystemLanguage =  "zh-CN"
    var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: XYZSpeech.SystemLanguage))! //"en-US"//"zh-Hans""en-US"/ //    语言识别变量
    //!"ja-Kana"))!//"zh-Hans"))!//"en-US"))! //"zh-TW" //"fr_FR"
    
    
    
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var SpeechBTN:UIButton?
    var commentTextField:UITextField?
    var 费用Field:UITextField?
    
    static func 切换语言状态()  {
        if XYZSpeech.SystemLanguage !=  "en-US"{
            print("切换了英文")
            XYZSpeech.SystemLanguage = "en-US"
            XYZSpeech.currentSTT?.speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: XYZSpeech.SystemLanguage))!
            
        }else{
            print("切换了中文")
            XYZSpeech.SystemLanguage = "zh-CN"
            XYZSpeech.currentSTT?.speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: XYZSpeech.SystemLanguage))!
        }
        
        
    }
    
    override init() {
        
    }
    
    init(SpeechBTN:UIButton,commentTextField:UITextField,费用Field:UITextField) {

        XYZSpeech.currentSTT?.speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: XYZSpeech.SystemLanguage))!
        
        
        self.SpeechBTN = SpeechBTN
        self.commentTextField = commentTextField
        self.费用Field = 费用Field
    }
    
    func 配置初始状态()  {
        
        speechRecognizer.delegate = self
        
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            @unknown default:
                print()
            }
            
            OperationQueue.main.addOperation() {
                self.SpeechBTN?.isEnabled = isButtonEnabled
            }
        }
    }
    
    

    func 切换识别状态(SpeechBTN:UIButton,commentTextField:UITextField,费用Field:UITextField) {
        
        if audioEngine.isRunning {
            
            commentTextField.text = ""
//            afterDelay(1, closure: {
//                self.commentTextField?.text = ""
//                self.commentTextField?.placeholder = "点按话筒语音输入"
//            })
            
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            inputNode.reset()
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
            
            SpeechBTN.isEnabled = false
//            SpeechBTN.setTitle("Start Recording", for: .normal)
            SpeechBTN.setImage(#imageLiteral(resourceName: "语音"), for: .normal)
            
            
            
        } else {
            SpeechBTN.setImage(#imageLiteral(resourceName: "语音开始"), for: .normal)
             commentTextField.placeholder = "备注"
            
            startRecording(SpeechBTN: SpeechBTN, commentTextField: commentTextField, 费用Field: 费用Field)
            
        
        }
    }
    
    
    func startRecording(SpeechBTN:UIButton,commentTextField:UITextField,费用Field:UITextField)  {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(.record, mode: .default, options: .allowAirPlay)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        let inputNode = audioEngine.inputNode
        //        guard let inputNode = audioEngine.inputNode else {
        //            fatalError("Audio engine has no input node")
        //        }  //4
        
//        guard let recognitionRequest = recognitionRequest else {
//            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
//        } //5
        
        recognitionRequest?.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
//      xxxxxxxxxxxxxxxxxxxxxxxxxx买东西条目名称整理
                
//                commentTextField.text = 买东西条目名称整理(输入: (result?.bestTranscription.formattedString) ?? "未识别")
//                费用Field.text = "\(找出数字算法(输入: result?.bestTranscription.formattedString ?? ""))"
                
                
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                SpeechBTN.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        
//        、、、、、、、、、、、、、、、、、、、、
        commentTextField.placeholder = "请靠近话筒"
        费用Field.placeholder = "主要识别花了后面的费用"

    }
    
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            SpeechBTN?.isEnabled = true
        } else {
            SpeechBTN?.isEnabled = false
        }
    }
    
    deinit {
        print("销毁了所有语音")
        
        commentTextField?.resignFirstResponder()
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        inputNode.reset()
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        //记得移除通知监听
        
        print("销毁了")
        NotificationCenter.default.removeObserver(self)
    }
    
}






//SpeechBTN.isEnabled = false
//currentSTT = SpeechToTextObject(SpeechBTN: SpeechBTN)
//currentSTT?.speechRecognizer.delegate = self
//currentSTT?.配置初始状态()
//
//
// currentSTT?.切换识别状态(SpeechBTN: SpeechBTN, TextView: TextView)
