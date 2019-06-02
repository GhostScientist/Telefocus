//
//  BLEScannerTableViewController.swift
//  Telefocus
//
//  Created by Dakota Kim on 4/25/19.
//  Copyright © 2019 Dakota Kim. All rights reserved.
//

import UIKit
import CoreBluetooth
import MBProgressHUD

class BLEScannerTableViewController: UITableViewController, BluetoothSerialDelegate {

    @IBOutlet weak var tryAgainButton: UIBarButtonItem!
    
    //MARK: Variables
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
    /// Progress hud shown
    var progressHUD: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tryAgainButton is only enabled when we've stopped scanning
        tryAgainButton.isEnabled = false
        
        // remove extra seperator insets (looks better imho)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // tell the delegate to notificate US instead of the previous view if something happens
        serial.delegate = self
        
        if serial.centralManager.state != .poweredOn {
            title = "Bluetooth not turned on"
            return
        }
        
        // start scanning and schedule the time out
        serial.startScan()
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(BLEScannerTableViewController.scanTimeOut), userInfo: nil, repeats: false)
    }

    @IBAction func cancelScanning(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Should be called 10s after we've begun scanning
    @objc private func scanTimeOut() {
        // timeout has occurred, stop scanning and give the user the option to try again
        serial.stopScan()
        tryAgainButton.isEnabled = true
        title = "Done scanning"
    }
    
    /// Should be called 10s after we've begun connecting
    @objc func connectTimeOut() {
        
        // don't if we've already connected
        if let _ = serial.connectedPeripheral {
            return
        }
        
        if let hud = progressHUD {
            hud.hide(animated: false)
        }
        
        if let _ = selectedPeripheral {
            serial.disconnect()
            selectedPeripheral = nil
        }
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = "Failed to connect"
        hud.hide(animated: true, afterDelay: 2.0)
    }
    
    
    //MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // return a cell with the peripheral name as text in the label
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let label = cell.viewWithTag(1) as! UILabel?
        label?.text = peripherals[(indexPath as NSIndexPath).row].peripheral.name
        return cell
    }
    
    
    //MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // the user has selected a peripheral, so stop scanning and proceed to the next view
        serial.stopScan()
        selectedPeripheral = peripherals[(indexPath as NSIndexPath).row].peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        progressHUD!.label.text = "Connecting"
        
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(BLEScannerTableViewController.connectTimeOut), userInfo: nil, repeats: false)
    }
    
    
    //MARK: BluetoothSerialDelegate
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // add to the array, next sort & reload
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append((peripheral: peripheral, RSSI: theRSSI))
        peripherals.sort { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        if let hud = progressHUD {
            hud.hide(animated: false)
        }
        
        tryAgainButton.isEnabled = true
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = "Failed to connect"
        hud.hide(animated: true, afterDelay: 1.0)
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        if let hud = progressHUD {
            hud.hide(animated: false)
        }
        
        tryAgainButton.isEnabled = true
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = "Failed to connect"
        hud.hide(animated: true, afterDelay: 1.0)
        
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        if let hud = progressHUD {
            hud.hide(animated: false)
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
        dismiss(animated: true, completion: nil)
    }
    
    func serialDidChangeState() {
        if let hud = progressHUD {
            hud.hide(animated: false)
        }
        
        if serial.centralManager.state != .poweredOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    //MARK: IBActions
    
    @IBAction func cancel(_ sender: AnyObject) {
        // go back
        serial.stopScan()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tryAgain(_ sender: AnyObject) {
        // empty array an start again
        peripherals = []
        tableView.reloadData()
        tryAgainButton.isEnabled = false
        title = "Scanning ..."
        serial.startScan()
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(BLEScannerTableViewController.scanTimeOut), userInfo: nil, repeats: false)
    }

}
