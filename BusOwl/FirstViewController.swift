//
//  FirstViewController.swift
//  BusOwl
//
//  Created by Ofer Raz on 3/22/20.
//  Copyright © 2020 Ofer Raz. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
   
    @IBOutlet weak var lowOilPView: UIView!
    @IBOutlet weak var highOilPView: UIView!
    @IBOutlet weak var rpmGaugeView: GaugeView!
    
    @IBOutlet weak var bleStatusView: UIView!
    @IBOutlet weak var coolantTempLable: UILabel!
    
    
    var rpmTimer: Timer?
    var coolantTempTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var bleManager = BLEManager.sharedInstance
        
        NotificationCenter.default.addObserver(self, selector: #selector(FirstViewController.lowOilPressureSensorNotification), name: NSNotification.Name(rawValue: lowOilPressureSwitchNotificationKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FirstViewController.highOilPressureSensorNotification), name: NSNotification.Name(rawValue: highOilPressureSwitchNotificationKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FirstViewController.bleConnectedNotification), name: NSNotification.Name(rawValue: bleConnectedNotificationKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FirstViewController.bleDisconnectedNotification), name: NSNotification.Name(rawValue: bleDisconnectedNotificationKey), object: nil)
        
        rpmTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireRpmTimer), userInfo: nil, repeats: true)
        coolantTempTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fireCoolantTempTimer), userInfo: nil, repeats: true)
        
        
        rpmGaugeView.backgroundColor = .clear

    }
    
    @objc func fireRpmTimer() {
        self.rpmGaugeView.value = BLEManager.sharedInstance.engineRPM.intValue
    }
    
    @objc func fireCoolantTempTimer() {
        coolantTempLable.text = "Coolant temp: " + BLEManager.sharedInstance.coolantTemp.stringValue
    }
    
    @objc func lowOilPressureSensorNotification() {
        updateOilPressureSensorsStatus()
    }
    
    @objc func highOilPressureSensorNotification() {
        updateOilPressureSensorsStatus()
    }
    
    @objc func bleConnectedNotification() {
        bleStatusView.backgroundColor = #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)
    }
    
    @objc func bleDisconnectedNotification() {
        bleStatusView.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
    }
    
    func updateOilPressureSensorsStatus() {
        var bleManager = BLEManager.sharedInstance
        if(bleManager.isLowOilPressureSwitchOpen == true) {
            lowOilPView.backgroundColor = #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)      // pressure is above 0.3 BAR
        } else {
            lowOilPView.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        }
        
        if(bleManager.isHighOilPressureSwitchOpen == true) {
            highOilPView.backgroundColor = #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1)     // pressure is above 0.9 BAR
        } else {
            highOilPView.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        }
    }
}
