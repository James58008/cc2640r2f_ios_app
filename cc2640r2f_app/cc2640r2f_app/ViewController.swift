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
    
    let algorithm = ECG_DataProcess()
    
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
    
    var bleLabel: UILabel!
    var verLabel: UILabel!
    var algVerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // ecg process callback
        algorithm.setCallBack(callBack: ecgProcessResultCallback)
        // ver
        verLabel = creatLabel(text: "V1.0", x: 190, y: 800, w: 100, h: 20)
        // algorithm er
        algVerLabel = creatLabel(text: "alg:"+algorithm.getVer(), x: 170, y: 820, w: 100, h: 20)
        
        // 创建按键
        creatButton(title: "噪声测试", x: 15, y: 200, w: 100, h: 50, action: #selector(noisButtonCallback))
        creatButton(title: "单导测试", x: 155, y: 200, w: 100, h: 50, action: #selector(ecgI_Callback))
        creatButton(title: "6导测试", x: 295, y: 200, w: 100, h: 50, action: #selector(ecg6_Callback))
        
        
        bleLabel = creatLabel(text: "搜索ECG设备...", x: 15, y: 100, w: 300, h: 50)

    }
    // 噪声测试
    @objc func noisButtonCallback() {
        print("hello")
        bleLabel.text = "ble1"
    }
    // 单导测试
    @objc func ecgI_Callback() {
        bleLabel.text = "i ceg"
    }
    // 6导测试
    @objc func ecg6_Callback() {
        bleLabel.text = "6 ecg"
    }
    
    // ecg信号处理结果
    func ecgProcessResultCallback(i: [Double], ii: [Double], iii: [Double], avr: [Double], avl: [Double], avf: [Double]) {
        
    }


}

