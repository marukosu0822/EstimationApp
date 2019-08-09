//
//  COGcalculate.swift
//  PoseEstimation-CoreML
//
//  Created by Vibteam on 2019/08/01.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import UIKit

class COGcalculate {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    //        "COG_ue",       //14   ={(R shoulder + L shoulder)/2}*61/100 + {(R hip + L hip)/2}*39/100
    //        "R COG_sita",   //15   =R hip * 56/100 + R knee * 44/100
    //        "L COG_sita",   //16   =L hip * 56/100 + L knee * 44/100
    //        "COG_sita",     //17   =(R COG_sita + L COG_sita) /2
    //
    //        "COG",          //18   =(COG_ue + COG_sita) /2
    
    open func show_COG_ue(R_shoulder : CGFloat? , L_shoulder : CGFloat? , R_hip : CGFloat? , L_hip : CGFloat?) -> CGFloat{
        
        if(R_shoulder != nil && L_shoulder != nil && R_hip != nil && L_hip  != nil ){
            let syoulder = (R_shoulder! + L_shoulder!)/2 * (61/100)
            let hip = (R_hip! + L_hip!)/2 * (39/100)
            let COG_ue = syoulder + hip
  //          print(COG_ue)
            return COG_ue
        }else{
  //          print("計測不可")
            return (0.0000)
  //          super.COG.text = "計測不可"
        }
    }
    
    open func show_R_COG_sita(R_hip : CGFloat? , R_knee : CGFloat?) -> CGFloat{
        if(R_hip != nil && R_knee != nil){
            let R_COG_sita = (R_hip!) * (56/100) + (R_knee!) * (44/100)
            return R_COG_sita
        }else{
            return (0.0000)
        }
    }
    
    open func show_L_COG_sita(L_hip : CGFloat? , L_knee : CGFloat?) -> CGFloat{
        if(L_hip != nil && L_knee != nil){
            let L_COG_sita = (L_hip!) * (56/100) + (L_knee!) * (44/100)
            return L_COG_sita
        }else{
            return (0.0000)
        }
    }
    
    open func show_COG_sita(R_COG_sita : CGFloat? , L_COG_sita : CGFloat?) -> CGFloat{
        if(R_COG_sita == 0.0000 || L_COG_sita == 0.0000){
            return (0.0000)
        }else{
            let COG_sita = (R_COG_sita! + L_COG_sita!)/2
            return COG_sita
        }
    }
    
    open func show_COG(COG_ue : CGFloat? , COG_sita : CGFloat?) -> CGFloat{
        if(COG_ue == 0.0000 || COG_sita == 0.0000){
            return (0.0000)
        }else{
            let COG = (COG_ue! + COG_sita!)/2
            return COG
        }
    }
    
}
//xy座標で出したい．

