//
//  TelefocusViewController.swift
//  Telefocus
//
//  Created by Dakota Kim on 4/5/19.
//  Copyright © 2019 Dakota Kim. All rights reserved.
//

import UIKit
import fluid_slider
import PureLayout
import CoreBluetooth

class TelefocusViewController: UIViewController, BluetoothSerialDelegate {
    
    let focusEmojis = ["😴", "🤓", "🤫", "🤖"]
    
    var allowTX = true
    var lastPosition: UInt8 = 255
    
    // Properties
    var focusFraction : UInt8 = 0 {
        willSet {
            switch(newValue) {
            case 0...45:
                emojiLabel.text = focusEmojis[0]
            case 46...90:
                emojiLabel.text = focusEmojis[1]
            case 91...135:
                emojiLabel.text = focusEmojis[2]
            case 136...180:
                emojiLabel.text = focusEmojis[3]
            default:
                break
            }
        }
    }
    
    //  Outlets
    var fluidSlider: Slider!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        serial = BluetoothSerial(delegate: self)
        setupSlider()
        setupConnectButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if serial.isReady {
            connectButton.isHidden = true
        }
    }

    private func setupSlider() {
        let pointOfOrigin : CGPoint = CGPoint(x: (view.frame.width/8), y: (view.frame.height / 4) * 3)
        let sizeOfSlider : CGSize = CGSize(width: (view.frame.width/8)*6, height: 40)
        fluidSlider = Slider(frame: CGRect(origin: pointOfOrigin, size: sizeOfSlider))
        fluidSlider.attributedTextForFraction = { fraction in
            let formatter = NumberFormatter()
            formatter.maximumIntegerDigits = 3
            formatter.maximumFractionDigits = 0
            let string = formatter.string(from: (fraction * 180) as NSNumber) ?? ""
            return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        }
        fluidSlider.setMinimumLabelAttributedText(NSAttributedString(string: "0", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white]))
        fluidSlider.setMaximumLabelAttributedText(NSAttributedString(string: "180", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white]))
        fluidSlider.fraction = 0.5
        fluidSlider.shadowOffset = CGSize(width: 0, height: 10)
        fluidSlider.shadowBlur = 5
        fluidSlider.shadowColor = UIColor(white: 0, alpha: 0.1)
        fluidSlider.contentViewColor = UIColor(red: 171/255.0, green: 168/255.0, blue: 220/255.0, alpha: 1)
        fluidSlider.valueViewColor = .white
        fluidSlider.addTarget(self, action: #selector(sliderValueChanged), for: UISlider.Event.valueChanged)
        fluidSlider.addTarget(self, action: #selector(sliderValueChanged), for: UISlider.Event.allTouchEvents)
        view.addSubview(fluidSlider)
    }
    
    private func setupConnectButton() {
        connectButton.backgroundColor = UIColor(red: 171/255.0, green: 168/255.0, blue: 220/255.0, alpha: 1)
        connectButton.clipsToBounds = true
        connectButton.layer.cornerRadius = connectButton.frame.height / 2.0
    }
    
    @objc private func sliderValueChanged() {
        guard let fraction = fluidSlider?.fraction else { return }
        focusFraction = UInt8(fraction * 180)
        sendToPeripheral(degrees: focusFraction)
        print("Dakota - fraction is \(focusFraction)")
    }
    
    // Bluetooth Stuff
    
    private func sendToPeripheral(degrees: UInt8) {
        if !allowTX {
            return
        }
        
        // 2
        // Validate value
        if degrees == lastPosition {
            return
        }
            // 3
        else if ((degrees < 0) || (degrees > 180)) {
            return
        }
        
        // 4
        // Send position to BLE Shield (if service exists and is connected)
        let data = Data([degrees])
        serial.sendDataToDevice(data)
    
        allowTX = false
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
            self.allowTX = true
        }
    }
    
    func serialDidChangeState() {
        print("Serial did change state.")
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        print("Serial did disconnect.")
    }
    
    @IBAction func connectButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "showScanner", sender: self)
    }
}
