//
//  Measure.swift
//  TurtleApp-CoreML
//
//  Created by GwakDoyoung on 03/07/2018.
//  Copyright © 2018 GwakDoyoung. All rights reserved.
//

import UIKit

protocol 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int)
}
// Performance Measurement
class 📏 {
    
    var delegate: 📏Delegate?//太郎が動かすときの約束事で，何をどう動かすのかを決める．上のやつ．だから，expansionでクラスに能力を付け足す．
    
    var index: Int = -1
    var measurements: [Dictionary<String, Double>]
    
    init() {
        let measurement = [
            "start": CACurrentMediaTime(),
            "end": CACurrentMediaTime()
        ]
        measurements = Array<Dictionary<String, Double>>(repeating: measurement, count: 30)//30個の箱を用意．
//        print("最初だけ実行される")
    }
    
    // start
    func 🎬👏() {
        index += 1
        index %= 30//indexは１から３０までをループ．つまり，常に直前３０個の時間データを持ちながら回る．
        measurements[index] = [:]
 //       print(index)
        🏷(for: index, with: "start")//時間を代入する関数．
 //       print("KOKOから始まり")
    }
    
    // stop
    func 🎬🤚() {
        
        🏷(for: index, with: "end")//終了時間をend行に代入
        
        let beforeMeasurement = getBeforeMeasurment(for: index)//前回の測定開始時刻
        let currentMeasurement = measurements[index]//今回の測定開始時刻
        if let startTime = currentMeasurement["start"],
            let endInferenceTime = currentMeasurement["endInference"],
            let endTime = currentMeasurement["end"],
            let beforeStartTime = beforeMeasurement["start"] {
            delegate?.updateMeasure(inferenceTime: endInferenceTime - startTime,//推測までかかった時間
                                    executionTime: endTime - startTime,//次の実行までにかかった時間
                                    fps: Int(1/(startTime - beforeStartTime)))//１秒に何回サンプリングできたか．
   //         print("KOKOで終わり")
        }
        
    }
    
    // labeling with
    func 🏷(with msg: String? = "") {
        🏷(for: index, with: msg)
//        print(index)
    }
    
    private func 🏷(for index: Int, with msg: String? = "") {
        if let message = msg {
            measurements[index][message] = CACurrentMediaTime()//現在の時間を代入
//            print(measurements[index][message])
        }
    }
    
    private func getBeforeMeasurment(for index: Int) -> Dictionary<String, Double> {
        return measurements[(index + 30 - 1) % 30]
    }
    
    // log
    func 🖨() {
        
    }
}

class MeasureLogView: UIView {
    let etimeLabel = UILabel(frame: .zero)
    let fpsLabel = UILabel(frame: .zero)
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
