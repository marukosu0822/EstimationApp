//
//  PoseView.swift
//  PoseEstimation-CoreML
//
//  Created by GwakDoyoung on 15/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit

class DrawingJointView: UIView {
    
    // the count of array may be <#14#> when use PoseEstimationForMobile's model
    private var keypointLabelBGViews: [UIView] = []

    public var bodyPoints: [PredictedPoint?] = [] {
        didSet {//プロパティの値に変化があったときに呼ばれるらしい．
            self.setNeedsDisplay()
            self.drawKeypoints(with: bodyPoints)
  //          print("koko")ここも繰り返される．
        }
    }
    
    private func setUpLabels(with keypointsCount: Int) {
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        keypointLabelBGViews = (0..<keypointsCount).map { index in
            let color = Constant.colors[index%Constant.colors.count]
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 4))
            view.backgroundColor = color
            view.clipsToBounds = false
            let label = UILabel(frame: CGRect(x: 4 + 3, y: -3, width: 100, height: 8))
            label.text = Constant.pointLabels[index%Constant.colors.count]
            label.textColor = color
            label.font = UIFont.preferredFont(forTextStyle: .caption2)
            view.addSubview(label)
            self.addSubview(view)
            return view
        }
        
        var x: CGFloat = 0.0
        let y: CGFloat = self.frame.size.height - 24
        let _ = (0..<keypointsCount).map { index in
            let color = Constant.colors[index%Constant.colors.count]
            if index == 2 || index == 8 { x += 28 }
            else { x += 14 }
            let view = UIView(frame: CGRect(x: x, y: y + 10, width: 4, height: 4))
            view.backgroundColor = color
            
            self.addSubview(view)
            return
        }
    }
    
    override func draw(_ rect: CGRect) {
        if let ctx = UIGraphicsGetCurrentContext() {
            
            ctx.clear(rect);
            
            let size = self.bounds.size
            
            let color = Constant.jointLineColor.cgColor
            if Constant.pointLabels.count == bodyPoints.count {
                let _ = Constant.connectingPointIndexs.map { pIndex1, pIndex2 in
                    if let bp1 = self.bodyPoints[pIndex1], bp1.maxConfidence > 0.5,
                        let bp2 = self.bodyPoints[pIndex2], bp2.maxConfidence > 0.5 {
                        let p1 = bp1.maxPoint
                        let p2 = bp2.maxPoint
                        let point1 = CGPoint(x: p1.x * size.width, y: p1.y*size.height)
                        let point2 = CGPoint(x: p2.x * size.width, y: p2.y*size.height)
                        drawLine(ctx: ctx, from: point1, to: point2, color: color)
//                        print("KOKOk")
                    }
                }
            }
        }
    }
    
    private func drawLine(ctx: CGContext, from p1: CGPoint, to p2: CGPoint, color: CGColor) {
        ctx.setStrokeColor(color)
        ctx.setLineWidth(3.0)
        
        ctx.move(to: p1)
        ctx.addLine(to: p2)
        
        ctx.strokePath();
    }
    
    private func drawKeypoints(with n_kpoints: [PredictedPoint?]) {
        let imageFrame = keypointLabelBGViews.first?.superview?.frame ?? .zero
        
        let minAlpha: CGFloat = 0.4
        let maxAlpha: CGFloat = 1.0
        let maxC: Double = 0.6
        let minC: Double = 0.1
        
        if n_kpoints.count != keypointLabelBGViews.count {
            setUpLabels(with: n_kpoints.count)
        }
        
        for (index, kp) in n_kpoints.enumerated() {
            if let n_kp = kp {
                let x = n_kp.maxPoint.x * imageFrame.width//imageFrame.widthは375一定
                let y = n_kp.maxPoint.y * imageFrame.height//imageFrame.heigftは500一定
//                print(imageFrame.height)
//                print(y)
                keypointLabelBGViews[index].center = CGPoint(x: x, y: y)
                let cRate = (n_kp.maxConfidence - minC)/(maxC - minC)
                keypointLabelBGViews[index].alpha = (maxAlpha - minAlpha) * CGFloat(cRate) + minAlpha
            } else {
                keypointLabelBGViews[index].center = CGPoint(x: -4000, y: -4000)
                keypointLabelBGViews[index].alpha = minAlpha
            }
        }
    }
}

// MARK: - Constant for edvardHua/PoseEstimationForMobile
struct Constant {
    static let pointLabels = [
        "top",          //0
        "neck",         //1
        
        "R shoulder",   //2
        "R elbow",      //3
        "R wrist",      //4
        "L shoulder",   //5
        "L elbow",      //6
        "L wrist",      //7
        
        "R hip",        //8
        "R knee",       //9
        "R ankle",      //10
        "L hip",        //11
        "L knee",       //12
        "L ankle",      //13
        
//        "COG_ue",       //14   ={(R shoulder + L shoulder)/2}*61/100 + {(R hip + L hip)/2}*39/100
//        "R COG_sita",   //15   =R hip * 56/100 + R knee * 44/100
//        "L COG_sita",   //16   =L hip * 56/100 + L knee * 44/100
//        "COG_sita",     //17   =(R COG_sita + L COG_sita) /2
//
//        "COG",          //18   =(COG_ue + COG_sita) /2
    ]
    
    static let connectingPointIndexs: [(Int, Int)] = [
        (0, 1),     // top-neck
        
        (1, 2),     // neck-rshoulder
        (2, 3),     // rshoulder-relbow
        (3, 4),     // relbow-rwrist
        (1, 8),     // neck-rhip
        (8, 9),     // rhip-rknee
        (9, 10),    // rknee-rankle
        
        (1, 5),     // neck-lshoulder
        (5, 6),     // lshoulder-lelbow
        (6, 7),     // lelbow-lwrist
        (1, 11),    // neck-lhip
        (11, 12),   // lhip-lknee
        (12, 13),   // lknee-lankle
        
    ]
    static let jointLineColor: UIColor = UIColor(displayP3Red: 87.0/255.0,
                                                 green: 255.0/255.0,
                                                 blue: 211.0/255.0,
                                                 alpha: 0.5)
    
    static let colors: [UIColor] = [
        .red,
        .green,
        .blue,
        .cyan,
        .yellow,
        .magenta,
        .orange,
        .purple,
        .brown,
        .black,
        .darkGray,
        .lightGray,
        .white,
        .gray,
        ]
}
