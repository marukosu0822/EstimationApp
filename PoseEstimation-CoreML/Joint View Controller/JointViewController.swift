//
//  ViewController.swift
//  PoseEstimation-CoreML
//
//  Created by GwakDoyoung on 05/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit
import Vision
import CoreMedia
import Accelerate
import MobileCoreServices
import CoreGraphics
import CoreVideo
import AVFoundation

class JointViewController: UIViewController {
    
    
    public typealias DetectObjectsCompletion = ([PredictedPoint?]?, Error?) -> Void//関数の別名をつけて，引数をすっきりさせる．
    
    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var jointView: DrawingJointView!
    @IBOutlet weak var labelsTableView: UITableView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    @IBOutlet weak var COG: UILabel!
    
    ///
    //ここにも深度のいれます．
    ///
    private let depthDataOutput = AVCaptureDepthDataOutput()
    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()//クラスのインスタンス化．📏()クラスの関数が使えるようになる．
    
    // MARK: - AV Property
    var videoCapture: VideoCapture!//VideoCaptureクラスのプロパティ．
    
    // MARK: - ML Properties
    // Core ML model
    typealias EstimationModel = model_cpm//クラス名変更．
    
    // Preprocess and Inference
    var request: VNCoreMLRequest?//VNCoreMLRequestクラスのプロパティ．
    var visionModel: VNCoreMLModel?//VNCoreMLModelクラスのプロパティ．
    
    // Postprocess
    var postProcessor: HeatmapPostProcessor = HeatmapPostProcessor()//インスタンス化．
    var mvfilters: [MovingAverageFilter] = []//箱の用意
    
    // Inference Result Data
    private var tableData: [PredictedPoint?] = []//箱の用意
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the model
        setUpModel()//下の方で定義してる．
//        print("一回通過")
        // setup camera
        setUpCamera()
//        print("一回通過")
        // setup tableview datasource on bottom
        labelsTableView.dataSource = self//dataSourceは一種のデリゲート．labelsTableViewによって動かされますよってこと．
//        print("一回通過")
        
        // setup delegate for performance measurement
        👨‍🔧.delegate = self//これもデリゲート．👨‍🔧によって動かされますよってこと．
//        print("一回通過")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
//        print("一回通過")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        self.videoCapture.start()//videoCapture動け！
//        print("一回通過")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()//videoCapture止まれ！
//        print("最後の最後に多分通過")
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: EstimationModel().model) {//try?で関数の例外を無視できる．戻り値がnilになる．学習データの読み取り？
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
//            print("ここは最初の一回通過")
        } else {
            fatalError()
        }
    }
    
    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture = VideoCapture()//videoCaptureのインスタンス化
        videoCapture.delegate = self//videocaptureクラスがデリゲートします．
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in//ここから別のキューに向かいます．
            
            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // start video preview when setup is done
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
//        print("ここ回る")
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
}

// MARK: - VideoCaptureDelegate
extension JointViewController: VideoCaptureDelegate {//ここは別のqueueです．
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        if let pixelBuffer = pixelBuffer {
            // start of measure
            self.👨‍🔧.🎬👏()
            print("よーいアクション！by太郎")
            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

extension JointViewController {
    // MARK: - Inferencing
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {//上で呼ばれる関数．ここで姿勢推定．
        guard let request = request else { fatalError() }
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)//引数ありのクラスのインスタンス化．だからinitでかいてあるよ．
        try? handler.perform([request])//いざ，推定！
        print("推定します")
    }
    
    // MARK: - Postprocessing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {//setupModelで呼ばれる関数．何故か繰り返される．ここがわからない部分です．
        self.👨‍🔧.🏷(with: "endInference")//endInference(推論終了)の行に時間を代入．直前３０個分保存．
        print("推測完了！")
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let heatmaps = observations.first?.featureValue.multiArrayValue {//多分結果を取得．
            
            /* =================================================================== */
            /* ========================= post-processing ========================= */
            
            /* ------------------ convert heatmap to point array ----------------- */
            var predictedPoints = postProcessor.convertToPredictedPoints(from: heatmaps)
            
            /* --------------------- moving average filter ----------------------- */
            if predictedPoints.count != mvfilters.count {
                mvfilters = predictedPoints.map { _ in MovingAverageFilter(limit: 3) }
//                         print("ここは３")
            }
//                   var l = 0
            for (predictedPoint, filter) in zip(predictedPoints, mvfilters) {
                filter.add(element: predictedPoint)

 //               filter.add(element: predictedPoint(maxPoint: (1 - x , y), maxConfidence: confidence))
 
 //              print("ここは４")//14回繰り返す．．．体の部位の数だけ繰り返してる！
//                          l = l + 1
//                          print(l)
//                           print(predictedPoint)
//                guard let hey = predictedPoint?.maxPoint.x else {fatalError()}///以下４行でpredictedPoint?.maxPointには0~1の数値が入ることがわかった．
//                if hey > CGFloat(0.8){
//                    fatalError()
//                }else{}
            }
     //       print(predictedPoints)
            predictedPoints = mvfilters.map { $0.averagedValue() }//多分フィルター.このフィルターでmaxconfidenceが補正されるみたい．
            //print(predictedPoints)
            
            
            for i in 0...13{//画面をフロントカメラにしたので，x方向の座標も反転させます．
                if predictedPoints[i]?.maxPoint.x != nil{
                    predictedPoints[i]!.maxPoint.x = 1 - predictedPoints[i]!.maxPoint.x
                }
            }
            
            
///////////////////////////////////////////////////////////////////////////
//この段階で一回分の14点の測定データが出力される．ということで，ここで重心の計算します．///
///////////////////////////////////////////////////////////////////////////
            
            /////////ここにも深度情報とるやついれときます//////////////////////////////
            
//            let depthData = syncedDepthData.depthData
//            let depthPixelBuffer = depthData.depthDataMap
            /////////////////////////////////////////////////////////////////////
            
            let COGkeisan = COGcalculate()

            if let R_shoulder_zisin = predictedPoints[2]?.maxConfidence, let L_shoulder_zisin = predictedPoints[5]?.maxConfidence, let R_knee_zisin = predictedPoints[9]?.maxConfidence, let L_knee_zisin = predictedPoints[12]?.maxConfidence{
                if (R_shoulder_zisin > 1.0 && L_shoulder_zisin > 1.0 && R_knee_zisin > 1.0 && L_knee_zisin > 1.0){
                    
                    var COG_ue_x = COGkeisan.show_COG_ue(R_shoulder: (predictedPoints[2]?.maxPoint.x),L_shoulder: (predictedPoints[5]?.maxPoint.x),R_hip: (predictedPoints[8]?.maxPoint.x),L_hip: (predictedPoints[11]?.maxPoint.x))
                    var R_COG_sita_x = COGkeisan.show_R_COG_sita(R_hip: (predictedPoints[8]?.maxPoint.x),R_knee: (predictedPoints[9]?.maxPoint.x))
                    var L_COG_sita_x = COGkeisan.show_L_COG_sita(L_hip: (predictedPoints[11]?.maxPoint.x),L_knee: (predictedPoints[12]?.maxPoint.x))
                    var COG_sita_x = COGkeisan.show_COG_sita(R_COG_sita: R_COG_sita_x , L_COG_sita: L_COG_sita_x)
                    var COG_x = COGkeisan.show_COG(COG_ue: COG_ue_x , COG_sita: COG_sita_x)
                    
                    var COG_ue_y = COGkeisan.show_COG_ue(R_shoulder: (predictedPoints[2]?.maxPoint.y),L_shoulder: (predictedPoints[5]?.maxPoint.y),R_hip: (predictedPoints[8]?.maxPoint.y),L_hip: (predictedPoints[11]?.maxPoint.y))
                    var R_COG_sita_y = COGkeisan.show_R_COG_sita(R_hip: (predictedPoints[8]?.maxPoint.y),R_knee: (predictedPoints[9]?.maxPoint.y))
                    var L_COG_sita_y = COGkeisan.show_L_COG_sita(L_hip: (predictedPoints[11]?.maxPoint.y),L_knee: (predictedPoints[12]?.maxPoint.y))
                    var COG_sita_y = COGkeisan.show_COG_sita(R_COG_sita: R_COG_sita_y , L_COG_sita: L_COG_sita_y)
                    var COG_y = COGkeisan.show_COG(COG_ue: COG_ue_y , COG_sita: COG_sita_y)
                    
                    //////////////////////////////////////////////////////////////////////////////////
                    /////////////////////////ここにも深度よみとるやついれていきます．//////////////////////////
                    /////////////////////////////////////////////////////////////////////////////////
                    
//                    let depthPoint = CGPoint(x: 640 * (1 - COG_y), y: 480 * (1 - COG_x))
//                    let COG_z = updateDepthLabel(depthFrame: depthPixelBuffer, depthPoint: depthPoint)
                    
                    
                    DispatchQueue.main.async {
                        self.COG.text = "(x,y,z) = (\(String(format: "%.2f", COG_x)) , \(String(format: "%.2f", COG_y)))"
                    }
                }else{
                    DispatchQueue.main.async {
                        self.COG.text = "N/A"
                    }
                }
            }else {
                DispatchQueue.main.async {
                    self.COG.text = "N/A"
                }
            }
            
            

            
//            print("ここは５")//
            /* =================================================================== */
            
            /* =================================================================== */
            /* ======================= display the results ======================= */
            DispatchQueue.main.sync {
                // draw line
                self.jointView.bodyPoints = predictedPoints
                
                // show key points description
                self.showKeypointsDescription(with: predictedPoints)//下で定義してる
//                print(predictedPoints)
                
                // end of measure
                self.👨‍🔧.🎬🤚()
                print("カーーーーーーッッットby太郎")
//                print("ここは６")
                
            }
            /* =================================================================== */
        } else {
            // end of measure
            self.👨‍🔧.🎬🤚()
          
        }
    }
    
    func showKeypointsDescription(with n_kpoints: [PredictedPoint?]) {//上で呼ばれる．予想点を代入．
        self.tableData = n_kpoints
//        print(self.tableData)
        self.labelsTableView.reloadData()//座標のテーブルをリセット．
    }
    
    ///ここにも深度読み取る関数いれます．
    func updateDepthLabel(depthFrame: CVPixelBuffer, depthPoint: CGPoint) -> (String) {
        
        assert(kCVPixelFormatType_DepthFloat16 == CVPixelBufferGetPixelFormatType(depthFrame))
        CVPixelBufferLockBaseAddress(depthFrame, .readOnly)
        let rowData = CVPixelBufferGetBaseAddress(depthFrame)! + Int(depthPoint.y) * CVPixelBufferGetBytesPerRow(depthFrame)
        // swift does not have an Float16 data type. Use UInt16 instead, and then translate
        var f16Pixel = rowData.assumingMemoryBound(to: UInt16.self)[Int(depthPoint.x)]
        CVPixelBufferUnlockBaseAddress(depthFrame, .readOnly)
        
        var f32Pixel = Float(0.0)
        var src = vImage_Buffer(data: &f16Pixel, height: 1, width: 1, rowBytes: 2)
        var dst = vImage_Buffer(data: &f32Pixel, height: 1, width: 1, rowBytes: 4)
        vImageConvert_Planar16FtoPlanarF(&src, &dst, 0)
        
        // Convert the depth frame format to cm
        let COG_z = String(format: "%.2f cm", f32Pixel * 100)
        return COG_z
    }
}

// MARK: - UITableView Data Source
extension JointViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tableData.count )// > 0 ? 1 : 0    //13個のデータがあると伝える．
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
//        print("答えた行の回数回ります．（画面に映っている行の数）")
        
        cell.textLabel?.text = Constant.pointLabels[indexPath.row]//13個の体の部位の名前表示．でも，常に実行されてるわけじゃなくて，デリゲートだから，
 //       ビューが画面に映っている時にそのデータが表示される．ビューテーブルによって引き起こされる部分だから．
        
//        // R elbow
//        if indexPath.row == 2 {
//
//            print(Constant.pointLabels[indexPath.row])
//
//            if let body_point = tableData[indexPath.row] {
//                let pointText: String = "\(String(format: "%.3f", body_point.maxPoint.x)), \(String(format: "%.3f", body_point.maxPoint.y))"
//                print("\(String(format: "%.3f", body_point.maxPoint.x)), \(String(format: "%.3f", body_point.maxPoint.y))")
//            } else {
//                cell.detailTextLabel?.text = "N/A"
//            }
//
//        }

//        if indexPath.row == 1{//デリゲートだから，こーゆー書き方だとその行をみる時しか実行されない．ビューテーブルによって引き起こされる部分だから．
//
//            if tableData[8] != nil && tableData[9] != nil{
//                let p = (tableData[8]!.maxPoint.x * 56/100)
//                let q = (tableData[9]!.maxPoint.x * 44/100)
//                print(p+q)
//            } else {
//                print("N/A")
//            }
//        }
        
        if let body_point = tableData[indexPath.row] {
            let pointText: String = "\(String(format: "%.3f", body_point.maxPoint.x)), \(String(format: "%.3f", body_point.maxPoint.y))"
            cell.detailTextLabel?.text = "(\(pointText)), [\(String(format: "%.3f", body_point.maxConfidence))]"
     //       print("onusi")
     //       print(tableData)
        } else {
            cell.detailTextLabel?.text = "N/A"
        }
        
        return cell
        
    }
}

// MARK: - 📏(Performance Measurement) Delegate
extension JointViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
//        print("ここも回る１")
        self.inferenceLabel.text = "inference: \(Int(inferenceTime*1000.0)) mm"
        self.etimeLabel.text = "execution: \(Int(executionTime*1000.0)) mm"
        self.fpsLabel.text = "fps: \(fps)"
        
    }
}
