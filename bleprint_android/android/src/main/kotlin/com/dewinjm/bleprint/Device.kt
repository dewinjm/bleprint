package com.dewinjm.bleprint

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothProfile

object Device {
    fun toJson(
        device: BluetoothDevice,
        state: Int? = BluetoothProfile.STATE_DISCONNECTED
    ): MutableMap<String, Any>? {
        if (device.name == null)
            return null

        val map: MutableMap<String, Any> = java.util.HashMap()
        map["address"] = device.address
        map["name"] = device.name
        map["type"] = device.type
        map["state"] = state!!
        return map
    }
}