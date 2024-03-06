//
//  ViewController.swift
//  ColorPicker
//
//  Created by Emilie Maria Nybo Arendttorp on 11/12/2023.
//

import UIKit
import SwiftUI

class ViewController: UIViewController, UIColorPickerViewControllerDelegate {
    
    private var rectangleView: UIView!
    private var colorPickerVC: UIColorPickerViewController!
    private var colorValuesLabel: UILabel!
    private var rectangleView1: UIView!
    private var whiteBoxView: UIView!
    private var submitButton: UIButton!
   
    var wantsSoftwareDimming: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = UIColor.systemGray5
        UIScreen.main.brightness = 1.0
        
        // The top rectangle beeing edited by the color picker
        let rectangleColor = UIColor.white
        let rectangleSize = CGSize(width: CGFloat(Int(UIScreen.main.bounds.width * 0.9)), height: CGFloat(Int(UIScreen.main.bounds.height * 0.35)))
        
        let yOffset = (view.bounds.height - rectangleSize.height) / 7
        let rectangleFrame = CGRect(x: (view.bounds.width - rectangleSize.width) / 2.0, y: yOffset, width: rectangleSize.width, height: rectangleSize.height)
        rectangleView = UIView(frame: rectangleFrame)
        rectangleView.backgroundColor = rectangleColor
        rectangleView.layer.cornerRadius = 20.0
        
        view.addSubview(rectangleView)
        
        // Function that updates the color
        func changeRectangleColor() {
            rectangleView.backgroundColor = UIColor.red // Change the color to your desired color
        }
 
        // The colorPicker
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        colorPickerVC.supportsAlpha = false
        addChild(colorPickerVC)
        view.addSubview(colorPickerVC.view)
    
        // Adjust the vertical spacing of the color picker
        colorPickerVC.view.frame.origin.y = rectangleFrame.maxY + 20
        
        // Add rounded corners to the color picker view
        colorPickerVC.view.layer.cornerRadius = 10.0
        colorPickerVC.didMove(toParent: self)
        
        // Create a white box (UIView)
        let whiteBox = UIColor.white
        let whiteBoxSize = CGSize(width: CGFloat(Int(UIScreen.main.bounds.width * 0.7)), height: CGFloat(Int(UIScreen.main.bounds.height * 0.06)))
        
        let yOffsetWhite = (view.bounds.height - whiteBoxSize.height) / 2.1
        let whiteBoxFrame = CGRect(x: (view.bounds.width - whiteBoxSize.width) / 2, y: yOffsetWhite, width: whiteBoxSize.width, height: whiteBoxSize.height)
        whiteBoxView = UIView(frame: whiteBoxFrame)
        whiteBoxView.backgroundColor = whiteBox
        whiteBoxView.layer.cornerRadius = 20.0
        
        view.addSubview(whiteBoxView)
        
        // Edit the placement of rgb values line 39 is the position adjustement
        colorValuesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        colorValuesLabel.textAlignment = .center
        colorValuesLabel.textColor = UIColor.black
        colorValuesLabel.center = CGPoint(x: view.bounds.width / 2.0, y: view.bounds.height / 2.0 - 23)
        updateColorValuesLabel(color: rectangleView.backgroundColor!)
        view.addSubview(colorValuesLabel)
            
        // The lowest rectangle
        let rectangle1Color = UIColor.systemGray5
        let rectangle1Size = CGSize(width: CGFloat(Int(UIScreen.main.bounds.width * 1)), height: CGFloat(Int(UIScreen.main.bounds.height * 0.06)))
        
        let yOffset1 = (view.bounds.height - rectangle1Size.height) / 1
        let rectangle1Frame = CGRect(x: (view.bounds.width - rectangle1Size.width) / 2.0, y: yOffset1, width: rectangle1Size.width, height: rectangle1Size.height)
        rectangleView1 = UIView(frame: rectangle1Frame)
        rectangleView1.backgroundColor = rectangle1Color
        rectangleView1.layer.cornerRadius = 20.0
        
        view.addSubview(rectangleView1)
        setupSubmitButton()
    }
    
    private func setupSubmitButton() {
        submitButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 100, width: view.bounds.width - 40, height: 50))
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitle("Submit Color", for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(didTapSubmitColor), for: .touchUpInside)
        view.addSubview(submitButton)
    }

    @objc private func didTapSubmitColor() {
        // Scale down animation to give feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.submitButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.submitButton.backgroundColor = .darkGray // Change color to indicate press
        }) { _ in
            // Scale back to normal
            UIView.animate(withDuration: 0.1) {
                self.submitButton.transform = .identity
                self.submitButton.backgroundColor = .systemBlue // Revert color
            }
        }
        
        if let color = rectangleView.backgroundColor {
            // Convert the selected color to P3 color space
            let p3Color = colorConversionToP3(color: color)
            
            // Extract P3 RGB components
            let rgbValues = p3Color.rgb()
            
            // Create an RGBValue struct with P3 RGB components
            let rgbValue = RGBValue(red: Int(rgbValues.red), green: Int(rgbValues.green), blue: Int(rgbValues.blue))
            
            // TODO: Key should be the target RGB value...
            let key = "selectedColorP3"
            
            // Save the P3 RGB value
            RGBStorage.shared.saveRGBValue(for: key, rgbValue: rgbValue)
            
            print("Saved P3 RGB Value: R: \(rgbValue.red), G: \(rgbValue.green), B: \(rgbValue.blue)")
            
            // Indicate success to the user
            submitButton.setTitle("Color Saved!", for: .normal)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // 2-second delay
                self.submitButton.setTitle("Submit Color", for: .normal)
            }
        }
    }
    
    @objc private func didTapSelectColor(){
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        colorPickerVC.supportsAlpha = false
        
        present(colorPickerVC, animated: true)
    }
    
    func colorConversionToP3(color: UIColor) -> UIColor{
        let p3Color: UIColor = {
            guard let colorSpace = CGColorSpace(name: CGColorSpace.displayP3),
                let cgColor = color.cgColor.converted(
                to: colorSpace,
                intent: .defaultIntent,
                options: nil
                ),
                let rgba = cgColor.components,
                rgba.count == 4
            else {
                return color
            }
            // FWIW, I could actually just use these component values directly instead
            return UIColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
        }()
        return p3Color
    }
    
    func updateColorValuesLabel(color: UIColor) {
        
        let p3Color = colorConversionToP3(color: color);
        
        colorValuesLabel.text = String(format: "R: %.0f  G: %.0f  B: %.0f", p3Color.rgb().red, p3Color.rgb().green, p3Color.rgb().blue)
        colorValuesLabel.font = UIFont.boldSystemFont(ofSize: 20)
       
        // Print the values of P3 in console
        print("\(p3Color.rgb().red),\(p3Color.rgb().green), \(p3Color.rgb().blue) ")
    }
    
    func printRGBValues(color: UIColor) {
        _ = color.rgb()
        //print("RGB Values: R: \(rgbValues.red), G: \(rgbValues.green), B: \(rgbValues.blue)")
    }
    
    @IBAction func colorPickerViewControllerDidFinish( _ viewController: UIColorPickerViewController) {
        _ = viewController.selectedColor
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        rectangleView.backgroundColor = color
        
        // Update the label with the new color's RGB values
        updateColorValuesLabel(color: rectangleView.backgroundColor!)
        
        // Reset the submit button's title to prompt for submission
        submitButton.setTitle("Submit Color", for: .normal)
    }
}

extension UIColor {
    func rgb() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red: red * 255, green: green * 255, blue: blue * 255, alpha: alpha)
    }
}
