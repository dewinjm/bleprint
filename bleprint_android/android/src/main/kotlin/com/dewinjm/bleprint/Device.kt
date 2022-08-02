package com.dewinjm.bleprint

import android.bluetooth.BluetoothDevice

object Device {
    fun toJson(device: BluetoothDevice): MutableMap<String, Any>? {
        if (device.name == null)
            return null

        val map: MutableMap<String, Any> = java.util.HashMap()
        map["address"] = device.address
        map["name"] = device.name
        map["type"] = device.type
        return map
    }
}