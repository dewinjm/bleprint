// Copyright (c) 2022 Dewin J. Martinez
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
        case "paired":
            bondedDevices();
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
    }
    
    private func hasStateError() ->FlutterError?{
        switch(self.centralState) {
        case .poweredOff:
            return FlutterError.init(code: "bluetooth_disabled", message: "is required Bluetooth enable", details: "\(centralState!)")
            
        case .poweredOn:
            print("poweredOn")
            return nil
            
        case .resetting:
            print("resetting")
            return nil
            
        case .unauthorized:
            return FlutterError.init(code: "bluetooth_unauthorized", message: "The app is not authorized to use Bluetooth", details: "\(centralState!)")
            
        case .unknown:
            return FlutterError.init(code: "bluetooth_unknown", message: "unknown", details: "\(centralState!)")
            
        case .unsupported:
            return FlutterError.init(code: "bluetooth_unavailable", message: "Bluetooth is unavailable", details: "\(centralState!)")
            
            
        default:
            return nil
        }
    }
    
    private func startScan(timer:NSNumber?) {
        let error = hasStateError()
        
        if error != nil {
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
    
    private func bondedDevices(){
        self.result?([])
    }
}
