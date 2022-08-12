// Copyright (c) 2022 Dewin J. Martinez
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Flutter
import UIKit
import CoreBluetooth

public class SwiftBleprintPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate {
    static let PERIOD_DEFAULT = 2.0
    
    private var channel: FlutterMethodChannel
    private var centralState: CBManagerState!
    private var manager: CBCentralManager!
    private var result: FlutterResult!
    private var peripherals: NSMutableDictionary!
    
    init(fromChannel channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bleprint_ios", binaryMessenger: registrar.messenger())
        let instance = SwiftBleprintPlugin.init(fromChannel: channel)
        
        instance.manager = CBCentralManager(delegate: instance, queue: nil)
        instance.peripherals = [:]
        
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
        case "connect":
            let arg = call.arguments as? NSArray
            let address = arg?[0] as? String
            let timer = arg?[1] as? NSNumber
            
            connect(deviceAddress: address, timer: timer)
        case "disconnect":
            let address = call.arguments as? String
            disconnect(deviceAddress: address)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil {
            self.peripherals.setValue(peripheral, forKey: peripheral.identifier.uuidString )
            
            let device : [String: Any] = [
                "address" : peripheral.identifier.uuidString,
                "name" : peripheral.name ?? "",
                "isConnected" : peripheral.state == CBPeripheralState.connected,
                "type" : 0
            ]
            
            channel.invokeMethod("onScanResult", arguments: device)
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager){
        self.centralState = central.state
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripherals.setValue(peripheral, forKey: peripheral.identifier.uuidString )
        self.result?(true)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if(error != nil ) {
            self.result?(FlutterError.init(code: "bluetooth_connect_failed", message: "device could not be connected", details: error))
            return
        }
        self.result?(false)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if(error != nil ) {
            self.result?(FlutterError.init(code: "bluetooth_disconnect_failed", message: "device could not be disconnected", details: error))
            return
        }
        self.result?(false)
    }

    private func hasStateError() -> FlutterError? {
        switch(self.centralState) {
        case .poweredOff:
            return FlutterError.init(code: "bluetooth_disabled", message: "is required Bluetooth enable", details: "\(centralState!)")
            
        case .poweredOn:
            return nil
            
        case .resetting:
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
            self.peripherals.removeAllObjects()
            result(error)
            return
        }
        
        if(manager.isScanning) {
            manager.stopScan()
        }
        
        peripherals.forEach { (key: Any, value: Any) in
            let peripheral: CBPeripheral? = value as? CBPeripheral
            if(peripheral?.state == CBPeripheralState.connected){
                manager.cancelPeripheralConnection(peripheral!)
            }
        }
        
        self.peripherals.removeAllObjects()
        self.result?(true)
        
        manager.scanForPeripherals(withServices: nil, options:nil)
        
        var seconds =  SwiftBleprintPlugin.PERIOD_DEFAULT
        
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
    
    private func connect(deviceAddress: String?, timer: NSNumber?) {
        let peripheral: CBPeripheral? = getPeripheral(deviceAddress: deviceAddress)
        
        if (peripheral == nil) {
            return
        }
        
        self.manager.connect(peripheral!, options: nil)
        
        var seconds =  SwiftBleprintPlugin.PERIOD_DEFAULT
        if timer != nil {
            seconds = timer!.doubleValue / 1000
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            if (peripheral!.state == CBPeripheralState.connecting) {
                self.manager.cancelPeripheralConnection(peripheral!)
            }
        }
    }
    
    private func disconnect(deviceAddress: String?) {
        let peripheral: CBPeripheral? = getPeripheral(deviceAddress: deviceAddress)
        
        if (peripheral == nil) {
            return
        }
        
        if (peripheral!.state == CBPeripheralState.connecting || peripheral!.state == CBPeripheralState.connected) {
            self.manager.cancelPeripheralConnection(peripheral!)
        } else {
            self.result?(nil)
        }
    }
    
    private func getPeripheral(deviceAddress: String?) -> CBPeripheral? {
        if (deviceAddress == nil) {
            self.result(FlutterError.init(code: "bluetooth_address_null", message: "address cannot be null", details: nil))
            return nil
        }
        
        let peripheral: CBPeripheral? = peripherals[deviceAddress!] as? CBPeripheral
        
        if (peripheral == nil) {
            self.result(FlutterError.init(code: "bluetooth_address_not_found", message: "the device address is not found", details: nil))
            return nil
        }
        
        if (manager.isScanning) {
            manager.stopScan()
        }
        
        return peripheral
    }
}
