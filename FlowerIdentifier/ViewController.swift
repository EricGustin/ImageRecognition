//
//  ViewController.swift
//  FlowerIdentifier
//
//  Created by Eric Gustin on 8/5/20.
//  Copyright © 2020 Eric Gustin. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController {

  @IBOutlet weak var predictionLabel: UILabel!
  @IBAction func takePhoto(_ sender: UIButton) {
    present(camera, animated: true)
  }
  private var camera: UIImagePickerController!
  
  lazy var classificationRequest: VNCoreMLRequest = {  // use Core ML to process images
      do {
        let model = try VNCoreMLModel(for: Food101().model)

          let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
              self?.processClassifications(for: request, error: error)
          })
          request.imageCropAndScaleOption = .centerCrop
          return request
      } catch {
          fatalError("Failed to load Vision ML model: \(error)")
      }
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setUpViews()
  }
  
  private func setUpViews() {
    predictionLabel.textColor = .black
    
    camera = UIImagePickerController()
    camera.sourceType = .camera
    camera.allowsEditing = true
    camera.delegate = self
  }
  
  private func createClassificationRequest(for image: UIImage) {
    predictionLabel.text = "Classifying type of food..."
  
    let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))  // ??? will this work ???
    
    guard let ciImage = CIImage(image: image) else {
      fatalError("Unable to create CIImage from UIImage")
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation ?? CGImagePropertyOrientation.up)
     do {
      try handler.perform([self.classificationRequest])
     }catch {
      print("Failed to perform \n\(error.localizedDescription)")
     }
    }
  }
  
  private func processClassifications(for request: VNRequest, error: Error?) {
    DispatchQueue.main.async {
      guard let results = request.results
        else {
          self.predictionLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
          return
      }
      let classifications = results as! [VNClassificationObservation]
      if classifications.isEmpty {
        self.predictionLabel.text = "Nothing recognized."
      } else {
        let topClassifications = classifications.prefix(1)
        let descriptions = topClassifications.map { classification in
          return String(format: "(%.2f) %@", classification.confidence, classification.identifier)
        }
        self.predictionLabel.text = descriptions.joined(separator: " |")
        
        // Ask user if they would like to open safari
        self.showAlertController(foodName: topClassifications[0].identifier.replacingOccurrences(of: "_", with: " "))
      }
    }
  }

  private func showAlertController(foodName: String) {
    let alert = UIAlertController(title: "Would you like to learn how to make \(foodName)?", message: "", preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "CANCEL", style: .default) { (action) in
      //
    }
    let yesAction = UIAlertAction(title: "YES", style: .default) { (action) in
      if let url = URL(string: "https://www.google.com/search?q=how%20to%20make%20\(foodName.replacingOccurrences(of: " ", with: "%20"))") {
        UIApplication.shared.open(url)
      }
    }
    alert.addAction(yesAction)
    alert.addAction(cancelAction)
    self.present(alert, animated: true) {
      //
    }
  }

}

extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)
    
    guard let image = info[.editedImage] as? UIImage else {
      print("Image taken by user not found.")
      return
    }
    createClassificationRequest(for: image)
    print(image.size)
  }
}

extension ViewController: UINavigationControllerDelegate {
  
}

