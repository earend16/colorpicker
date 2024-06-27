import UIKit
import SwiftUI
import AVFoundation

class ViewController: UIViewController, UIColorPickerViewControllerDelegate {
    
    private var rectangleView: UIView!
    private var colorPickerVC: UIColorPickerViewController!
    private var colorValuesLabel: UILabel!
    private var rectangleView1: UIView!
    private var whiteBoxView: UIView!
    private var submitButton: UIButton!
    private var audioPlayer: AVAudioPlayer?
   
    var wantsSoftwareDimming: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray5
        UIScreen.main.brightness = 1.0
        
        setupSubmitButton()

        // Adjust the yOffset values to account for the submit button at the top
        let submitButtonHeight: CGFloat = 50 + 20 // Button height plus some padding

        // The top rectangle being edited by the color picker
        let rectangleColor = UIColor.white
        let rectangleSize = CGSize(width: CGFloat(Int(UIScreen.main.bounds.width * 0.9)), height: CGFloat(Int(UIScreen.main.bounds.height * 0.35)))
        let yOffset = (view.bounds.height - rectangleSize.height) / 7 + submitButtonHeight
        let rectangleFrame = CGRect(x: (view.bounds.width - rectangleSize.width) / 2, y: yOffset - 20, width: rectangleSize.width , height: rectangleSize.height - 30)
        rectangleView = UIView(frame: rectangleFrame)
        rectangleView.backgroundColor = rectangleColor
        rectangleView.layer.cornerRadius = 20.0
        view.addSubview(rectangleView)
        
        // Function that updates the color
        func changeRectangleColor() {
            rectangleView.backgroundColor = UIColor.red
        }
 
        // The colorPicker
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        colorPickerVC.supportsAlpha = false
        addChild(colorPickerVC)
        view.addSubview(colorPickerVC.view)
        colorPickerVC.view.frame.origin.y = rectangleFrame.maxY + 20 // Adjust the vertical spacing of the color picker
        colorPickerVC.view.layer.cornerRadius = 10.0 // Add rounded corners to the color picker view
        colorPickerVC.didMove(toParent: self)
        
        // Create a white box (UIView)
        let whiteBox = UIColor.white
        let whiteBoxSize = CGSize(width: CGFloat(Int(UIScreen.main.bounds.width * 0.7)), height: CGFloat(Int(UIScreen.main.bounds.height * 0.06)))
        let yOffsetWhite = (view.bounds.height - whiteBoxSize.height) / 2.35 + submitButtonHeight
        let whiteBoxFrame = CGRect(x: (view.bounds.width - whiteBoxSize.width) / 2, y: yOffsetWhite, width: whiteBoxSize.width, height: whiteBoxSize.height)
        whiteBoxView = UIView(frame: whiteBoxFrame)
        whiteBoxView.backgroundColor = whiteBox
        whiteBoxView.layer.cornerRadius = 20.0
        view.addSubview(whiteBoxView)
        
        colorValuesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        colorValuesLabel.textAlignment = .center
        colorValuesLabel.textColor = UIColor.black
        colorValuesLabel.center = CGPoint(x: view.bounds.width / 2.0, y: view.bounds.height / 2.0 - 60 + submitButtonHeight)
        updateColorValuesLabel(color: rectangleView.backgroundColor!)
        view.addSubview(colorValuesLabel)
            
        // The lowest rectangle that hides parts of the color picker that we're not interested in
        rectangleView1 = UIView()
        rectangleView1.backgroundColor = UIColor.systemGray5
        rectangleView1.layer.cornerRadius = 20.0
        rectangleView1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rectangleView1)
        
        // Constraints to make the layout transferable to both 15 Pro and 15 Pro Max
        NSLayoutConstraint.activate([
            rectangleView1.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 60), // 60 points from the bottom
            rectangleView1.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rectangleView1.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rectangleView1.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.1)
        ])
        
        setupAudioPlayer()
        
        // Run the test for RGBStorage
        RGBStorage.shared.testRGBConversion()
    }
    
    private func setupSubmitButton() {
        submitButton = UIButton(frame: CGRect(x: 20, y: 65, width: view.bounds.width - 40, height: 50))
        submitButton.backgroundColor = .black
        submitButton.setTitle("Submit Color", for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(didTapSubmitColor), for: .touchUpInside)
        view.addSubview(submitButton)
    }
    
    private func setupAudioPlayer() {
        if let soundURL = Bundle.main.url(forResource: "submit_sound", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading sound file: \(error)")
            }
        }
    }

    @objc private func didTapSubmitColor() {
        // Play the sound
        audioPlayer?.play()
        
        // Proceed with the existing logic to convert the selected color and save it
        if let color = rectangleView.backgroundColor {
            let p3Color = colorConversionToP3(color: color)
            let rgbValues = p3Color.rgb()
            let rgbValue = RGBValue(red: rgbValues.red, green: rgbValues.green, blue: rgbValues.blue)
            
            // Save the P3 RGB value
            RGBStorage.shared.saveRGBValue(rgbValue: rgbValue)
            
            // Provide user feedback
            UIView.animate(withDuration: 0.1, animations: {
                self.submitButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.submitButton.backgroundColor = .darkGray
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.submitButton.transform = .identity
                    self.submitButton.backgroundColor = .black  // Maintain black color after animation
                    self.submitButton.setTitle("Color Saved!", for: .normal)
                }
                
                // Revert the button's title after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.submitButton.setTitle("Submit Color", for: .normal)
                }
            }
            
            print("Saved P3 RGB Value: R: \(rgbValue.red), G: \(rgbValue.green), B: \(rgbValue.blue)")
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
    
    @IBAction func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
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
