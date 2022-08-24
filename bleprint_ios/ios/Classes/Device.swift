// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import CoreBluetooth

public class Device{
    
    /// Convert CBPeripheral to Json Map
    class func toJson(peripheral: CBPeripheral) -> [String: Any]{
        let device : [String: Any] = [
            "address" : peripheral.identifier.uuidString,
            "name" : peripheral.name ?? "",
            "state" : peripheral.state.rawValue
        ]
        return device
    }
}
