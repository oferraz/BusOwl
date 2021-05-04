//
//  BLEManager.swift
//  BusOwl
//
//  Created by Ofer Raz on 3/28/20.
//  Copyright © 2020 Ofer Raz. All rights reserved.
//

import Foundation
import CoreBluetooth

let lowOilPressureSwitchNotificationKey = "com.busowl.lowOilPressureSwitchNotificationKey"
let highOilPressureSwitchNotificationKey = "com.busowl.highOilPressureSwitchNotificationKey"
let bleConnectedNotificationKey = "com.busowl.bleConnectedNotificationKey"
let bleDisconnectedNotificationKey = "com.busowl.bleDisconnectedNotificationKey"

let engineDataServiceCBUUID = CBUUID(string: "66fce8ee-b881-4065-9a5f-8f4f3a961b73")
let engineRpmCharacteristicCBUUID = CBUUID(string: "94734ac7-fcf6-4471-a32c-e3524393738b")
let engineLowOilPCharacteristicCBUUID = CBUUID(string: "74c9a07f-5ad0-421f-9c81-7ba247febe18")
let engineHighOilPCharacteristicCBUUID = CBUUID(string: "cd01c743-d28f-435d-b156-a3cf00b1d290")
let engineCoolantTempPCharacteristicCBUUID = CBUUID(string: "4dfd6cb9-ff36-42cc-9742-c49c9e2e2c70")

final class BLEManager : NSObject {
    static let sharedInstance = BLEManager()
    
    var centralManager : CBCentralManager?
    var vanOwlPeripheral: CBPeripheral? = nil
    
    var engineRPM: NSNumber = 0
    var coolantTemp: NSNumber = 0
    var isLowOilPressureSwitchOpen = false       //close above 0.3 bar
    var isHighOilPressureSwitchOpen = false     //open above 0.9 bar
    
    
    /// Save the single instance
    static private var instance : BLEManager {
        return sharedInstance
    }
    
    
    
    private override init() {
        super.init()
        initCBCentralManager()
    }
    
    
    /**
    Initialize CBCentralManager instance
    */
    func initCBCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

// MARK: Central Manager Extension

extension BLEManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {

        case .unknown:
          print("central.state is .unknown")
        case .resetting:
          print("central.state is .resetting")
        case .unsupported:
          print("central.state is .unsupported")
        case .unauthorized:
          print("central.state is .unauthorized")
        case .poweredOff:
          print("central.state is .poweredOff")
        case .poweredOn:
          print("central.state is .poweredOn")
          centralManager!.scanForPeripherals(withServices: [engineDataServiceCBUUID]) //withServices: [engineDataServiceCBUUID]
        @unknown default:
            print("Something wrong with BLE")
            
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        vanOwlPeripheral = peripheral
        vanOwlPeripheral!.delegate = self
        centralManager!.stopScan()
        centralManager!.connect(vanOwlPeripheral!)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        vanOwlPeripheral!.discoverServices([engineDataServiceCBUUID])
        NotificationCenter.default.post(name: Notification.Name(rawValue: bleConnectedNotificationKey), object: nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        vanOwlPeripheral = nil;
        centralManager!.scanForPeripherals(withServices: [engineDataServiceCBUUID])
        NotificationCenter.default.post(name: Notification.Name(rawValue: bleDisconnectedNotificationKey), object: nil)
    }
}

extension BLEManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
      guard let characteristics = service.characteristics else { return }

      for characteristic in characteristics {
        print(characteristic)
        if characteristic.properties.contains(.read) {
            print("\(characteristic.uuid): properties contains .read")
            peripheral.readValue(for: characteristic)
        }
        if characteristic.properties.contains(.notify) {
            print("\(characteristic.uuid): properties contains .notify")
            peripheral.setNotifyValue(true, for: characteristic)
        }
      }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
      switch characteristic.uuid {
        case engineRpmCharacteristicCBUUID:
            let data = characteristic.value
            var bigNum = Int32(0)
            withUnsafeMutableBytes(of: &bigNum) {
              data!.copyBytes(to: $0, from: 0..<MemoryLayout<Int32>.size)
            }
            engineRPM = bigNum as NSNumber
            break
        
        case engineLowOilPCharacteristicCBUUID:
            let data = characteristic.value![0]
            if(data == 0) {
                isLowOilPressureSwitchOpen = false
            } else {
                isLowOilPressureSwitchOpen = true
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: lowOilPressureSwitchNotificationKey), object: nil)
        
        case engineHighOilPCharacteristicCBUUID:
            let data = characteristic.value![0]
            if(data == 0) {
                isHighOilPressureSwitchOpen = false
            } else {
                isHighOilPressureSwitchOpen = true
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: highOilPressureSwitchNotificationKey), object: nil)
        
        case engineCoolantTempPCharacteristicCBUUID:
            let data = characteristic.value
            var bigNum = Int32(0)
            withUnsafeMutableBytes(of: &bigNum) {
              data!.copyBytes(to: $0, from: 0..<MemoryLayout<Int32>.size)
            }
            coolantTemp = bigNum as NSNumber
        
        
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
    }
}
