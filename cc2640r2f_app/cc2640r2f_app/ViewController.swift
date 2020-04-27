//
//  ViewController.swift
//  cc2640r2f_app
//
//  Created by JamesLi on 2020/4/26.
//  Copyright © 2020 JamesLi. All rights reserved.
//

import UIKit
import LeadECG_algorithm

class ViewController: UIViewController {
    
    var queue = Queue<ECG_Data>()
    
    var drawView1: DrawSingleView?
    var drawView2: DrawSingleView?
    
    let algorithm = ECG_Interface()
    let ble = BleManager()
    
    var speedTimer = Timer()
    var viewDrawTimer: CADisplayLink?
    var receiveCount: Int = 0
    
    var bleLabel: UILabel!
    var verLabel: UILabel!
    var speedLabel: UILabel!
    var view1MsgLabel: UILabel!
    var view2MsgLabel: UILabel!
    var viewRulerLabel: UILabel!
    var displayMode: Int = 0
    var displayDownSample: Int = 0
    var displayBuffCount: Int = 0
    
    var disBuff_i = [Double](repeating: 0.0, count: 3900)
    var disBuff_ii = [Double](repeating: 0.0, count: 3900)
    var disBuff_iii = [Double](repeating: 0.0, count: 3900)
    var disBuff_avr = [Double](repeating: 0.0, count: 3900)
    var disBuff_avl = [Double](repeating: 0.0, count: 3900)
    var disBuff_avf = [Double](repeating: 0.0, count: 3900)

    
    func creatButton(title: String, x: Int, y: Int, w: Int, h: Int, action: Selector) {
        let button: UIButton = UIButton(type: .system)
        button.frame = CGRect(x: x, y: y, width: w, height: h)
        button.setTitle(title, for: UIControl.State.normal)
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 10
        self.view.addSubview(button)
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    func creatLabel(text: String, x: Int, y: Int, w: Int, h: Int) -> UILabel {
        let label = UILabel.init(frame: CGRect(origin:CGPoint(x:x,y:y),size:CGSize(width:w, height:h)))
        label.textColor = UIColor.black
        label.text = text
        label.font = UIFont.systemFont(ofSize:17)
         self.view.addSubview(label)
        return label
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // ecg process callback
        algorithm.setCallBack(callBack: ecgProcessResultCallback)
        // ble msg
        bleLabel = creatLabel(text: "搜索ECG设备...", x: 15, y: 50, w: 300, h: 20)
        // 通信速率
        speedLabel = creatLabel(text: "通信速率：", x: 15, y: 75, w: 200, h: 20)
        // ver
        verLabel = creatLabel(text: algorithm.getVer(), x: 350, y: 75, w: 100, h: 20)
        //波形显示窗口
        drawView1 = DrawSingleView.init(frame: CGRect.init(x: 10, y: 100, width: 390, height: 200))
        self.view.addSubview(drawView1!)
        drawView2 = DrawSingleView.init(frame: CGRect.init(x: 10, y: 310, width: 390, height: 200))
        self.view.addSubview(drawView2!)
        // 窗口波形显示信息
        view1MsgLabel = creatLabel(text: "I", x: 20, y: 105, w: 100, h: 20)
        view2MsgLabel = creatLabel(text: "II", x: 20, y: 315, w: 100, h: 20)
        // 窗口波形单位
        viewRulerLabel = creatLabel(text: "10mm/mV 25mm/S", x: 135, y: 520, w: 200, h: 20)
        // 创建按键
        creatButton(title: "显示I & II", x: 15, y: 560, w: 100, h: 50, action: #selector(buttonCallbackI_II))
        creatButton(title: "显示III", x: 155, y: 560, w: 100, h: 50, action: #selector(buttonCallback_III))
        creatButton(title: "显示aVR", x: 295, y: 560, w: 100, h: 50, action: #selector(buttonCallback_aVR))
        creatButton(title: "显示aVL", x: 15, y: 630, w: 100, h: 50, action: #selector(buttonCallback_aVL))
        creatButton(title: "显示aVF", x: 155, y: 630, w: 100, h: 50, action: #selector(butonCallback_aVF))
        // ble
        ble.logPrint = { (backMsg) in
            self.bleMsg(msg: backMsg)
        }
        ble.bleDataProcess = { (backMsg) in
            self.bleDataProcess(bleData: backMsg)
        }
        ble.bleStatusSet = { (backMsg) in
            self.bleStatus(status: backMsg)
            
        }
        ble.bleManagerInit() // 打开ble

    }
    // 显示I&II
    @objc func buttonCallbackI_II() {
        displayMode = 0
        view1MsgLabel.text = "I"
    }
    // 显示III
    @objc func buttonCallback_III(){
        displayMode = 1
        view1MsgLabel.text = "III"
    }
    // 显示aVR
    @objc func buttonCallback_aVR() {
        displayMode = 2
        view1MsgLabel.text = "aVR"
    }
    // 显示aVL
    @objc func buttonCallback_aVL() {
        displayMode = 3
        view1MsgLabel.text = "aVL"
    }
    // 显示aVF
    @objc func butonCallback_aVF() {
        displayMode = 4
        view1MsgLabel.text = "aVF"
    }
    
    // ble msg
    func bleMsg(msg: String) {
        bleLabel.text = msg
    }
    func bleStatus(status: UInt8) {
        if status == 1 { // 开始监听数据
            receiveCount = 0
            displayMode = 0
            displayDownSample = 0
            displayBuffCount = 0
            speedTimerStart()
            viewDrawTimerStart()
        }
        else if status == 2 {
            speedTimer.invalidate()
            viewDrawTimer?.invalidate()
        }
    }
    
    // ble Data
    func bleDataProcess(bleData: [UInt8]) {
        receiveCount += Int(bleData.count)
        // 数据处理
        algorithm.ECG_Process(ecgData: bleData)
    }
    
    // ecg信号处理结果
    func ecgProcessResultCallback(i: [Double], ii: [Double], iii: [Double], avr: [Double], avl: [Double], avf: [Double]) {
        var ecg_data: ECG_Data = ECG_Data(i: 0, ii: 0, iii: 0, avr: 0, avl: 0, avf: 0)

        for k in 0...49 {
            ecg_data.i = i[k]
            ecg_data.ii = ii[k]
            ecg_data.iii = iii[k]
            ecg_data.avr = avr[k]
            ecg_data.avl = avl[k]
            ecg_data.avf = avf[k]
            queue.enqueue(element: ecg_data)
        }
        
    }
    
    // 波形显示定时器
    func viewDrawTimerStart() {
        viewDrawTimer = CADisplayLink(target: self, selector: #selector(self.viewDrawTimerInterrupt))
        viewDrawTimer?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    @objc func viewDrawTimerInterrupt() {
        var ecg_data: ECG_Data!
        var points_i:[CGPoint] = []
        var points_ii:[CGPoint] = []
        var points_iii:[CGPoint] = []
        var points_avr:[CGPoint] = []
        var points_avl:[CGPoint] = []
        var points_avf:[CGPoint] = []
//        print(queue.count)
        let th: Double = 40
        while queue.count > 0 {
                ecg_data = queue.dequeue()
                disBuff_i[displayBuffCount] = ecg_data.i * th
                disBuff_ii[displayBuffCount] = ecg_data.ii * th
                disBuff_iii[displayBuffCount] = ecg_data.iii * th
                disBuff_avr[displayBuffCount] = ecg_data.avr * th
                disBuff_avl[displayBuffCount] = ecg_data.avl * th
                disBuff_avf[displayBuffCount] = ecg_data.avf * th
                displayBuffCount += 1
                if displayBuffCount == 390*5 {
                    displayBuffCount = 0
                }
        }
        displayDownSample += 1
        if displayDownSample < 5 {
            return
        }
        displayDownSample = 0

        for i in 0...389*5 {
            points_i.append(CGPoint.init(x: Double(i)/5, y: 100 - disBuff_i[Int(i)]))
            points_ii.append(CGPoint.init(x: Double(i)/5, y: 100 - disBuff_ii[Int(i)]))
            points_iii.append(CGPoint.init(x: Double(i)/5, y: 100 - disBuff_iii[Int(i)]))
            points_avr.append(CGPoint.init(x: Double(i)/5, y: 100 - disBuff_avr[Int(i)]))
            points_avl.append(CGPoint.init(x: Double(i)/5, y: 100 - disBuff_avl[Int(i)]))
            points_avf.append(CGPoint.init(x: Double(i)/5, y: 100 - disBuff_avf[Int(i)]))
        }
        drawView2?.curveView?.setFlg(val: displayBuffCount)
        drawView2?.points = points_ii
        if displayMode == 0 { // I & II
            drawView1?.curveView?.setFlg(val: displayBuffCount)
            drawView1?.points = points_i
        } else if displayMode == 1 { // III
            drawView1?.curveView?.setFlg(val: displayBuffCount)
            drawView1?.points = points_iii
        } else if displayMode == 2{
            drawView1?.curveView?.setFlg(val: displayBuffCount)
            drawView1?.points = points_avr
        } else if displayMode == 3 {
            drawView1?.curveView?.setFlg(val: displayBuffCount)
            drawView1?.points = points_avl
        } else if displayMode == 4 {
            drawView1?.curveView?.setFlg(val: displayBuffCount)
            drawView1?.points = points_avf
        }
    }
    
    // 通信速率定时器
    func speedTimerStart() {
        speedTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.speedTimerInterrupt), userInfo: nil, repeats: true)
    }
    @objc func speedTimerInterrupt() {
        speedLabel.text = "通信速率:" + String(format: "%.1fKiB/s", Float(receiveCount)/1024)
        receiveCount = 0
    }


}

