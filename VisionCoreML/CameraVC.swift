//
//  ViewController.swift
//  VisionCoreML
//
//  Created by Tomasz Jaeschke on 08/03/2019.
//  Copyright © 2019 Tomasz Jaeschke. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case on
    case off
}

class CameraVC: UIViewController {

    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    
    var flashControlSate: FlashState = .off
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashBtn: RoundedShadowBtn!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var identyficationLbl: UILabel!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTouchesRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
            
        } catch  {
            debugPrint(error)
        }
    }
    
    @objc func didTapCameraView() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
        
        settings.previewPhotoFormat = previewFormat
        
        if flashControlSate == .off {
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?){
        // Its how our model "think"
        guard let results = request.results as? [VNClassificationObservation] else { return }
//        for classification in results {
//            if classification.confidence < 0.5 {
//                self.identyficationLbl.text = "I'm not sure wht this is. Please try again."
//                self.confidenceLbl.text = ""
//                print("It's: \(classification.identifier) confidence: \(classification.confidence*100)%")
//                break
//            } else {
//                print("\(classification.identifier)")
//                self.identyficationLbl.text = classification.identifier
//                self.confidenceLbl.text = "Confidence: \(Int(classification.confidence * 100))%"
//                break
//            }
        let textFromResult = results.first!.identifier
        var description = textFromResult.suffix((textFromResult.count - 10))
        
        
        self.identyficationLbl.text = "It's: \(description)"
        self.confidenceLbl.text = "Confidence: \(Int(results.first!.confidence * 100))%"
        }
    
    @IBAction func flashBtnWasPressed(_ sender: Any) {
        switch flashControlSate {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlSate = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlSate = .off
        }
    }
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do {
                let model = try VNCoreMLModel(for: MobileNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                request.imageCropAndScaleOption = .centerCrop
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
        }
    }
}
