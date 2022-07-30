// Copyright (c) 2022 dewin
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Flutter
import UIKit
import CoreBluetooth

public class SwiftBleprintPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate {
    static let SCAN_PERIOD_DEFAULT = 2.0
    
    private var channel: FlutterMethodChannel
    private var centralState: CBManagerState!
    private var manager: CBCentralManager!
    private var result: FlutterResult!
    
    init(fromChannel channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bleprint_ios", binaryMessenger: registrar.messenger())
        let instance = SwiftBleprintPlugin.init(fromChannel: channel)
        
        instance.manager = CBCentralManager(delegate: instance, queue: nil)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        
        switch call.method {
        case "getPlatformName":
            result("iOS")
        case "isAvailable":
            result(centralState != .unsupported)
        case "isEnabled":
            result(centralState == .poweredOn)
        case "scan":
            let value = call.arguments as? NSNumber
            startScan(timer: value)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil {
            //scannedPeripherals.set(peripheral, forKey: peripheral?.identifier.uuidString ?? "")
            
            let device = [
                "address" : peripheral.identifier.uuidString,
                "name" : peripheral.name ?? "",
                "type" : nil
            ]
            
            channel.invokeMethod("onScanResult", arguments: device)
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager){
        self.centralState = central.state
        
        switch(central.state) {
        case .poweredOff:
            let error = FlutterError.init(code: "bluetooth_poweredOff", message: "Bluetooth is currently powered off", details: central.state)
            print(error.code)
            
        case .poweredOn:
            print("poweredOn")
            
        case .resetting:
            print("resetting")
            
        case .unauthorized:
            let error = FlutterError.init(code: "bluetooth_unauthorized", message: "The app is not authorized to use Bluetooth Low Energy", details: central.state)
            print(error.code)
                        
        case .unknown:
            let error = FlutterError.init(code: "bluetooth_unknown", message: "unknown", details: central.state)
            print(error.code)
                       
        case .unsupported:
            let error = FlutterError.init(code: "bluetooth_unsupported", message: "The platform/hardware doesn't support Bluetooth Low Energy", details: central.state)
            print(error.code)
                        
        default:
            print("default")
            break
        }
    }
    
    private func startScan(timer:NSNumber?) {
        if(centralState != .poweredOn){
            let error = FlutterError(code: "scan_error", message: "can only accept this command while in the powered on state", details: "\(centralState!)")
            result(error)
            return
        }
        
        if(manager.isScanning) {
            manager.stopScan()
        }
        
        manager.scanForPeripherals(withServices: nil, options:nil)
        self.result?(true)
        var seconds =  SwiftBleprintPlugin.SCAN_PERIOD_DEFAULT
        
        if timer != nil {
            seconds = timer!.doubleValue / 1000
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.stopScan()
        }
    }
    
    private func stopScan(){
        self.manager.stopScan()
        self.channel.invokeMethod("onStopScan", arguments: false)
    }
}
