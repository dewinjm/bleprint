package com.dewinjm.bleprint

import android.Manifest
import android.app.Activity
import android.bluetooth.*
import android.bluetooth.BluetoothAdapter.LeScanCallback
import android.bluetooth.le.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class BleprintPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener {
    companion object {
        const val DEFAULT_SCAN_PERIOD: Long = 2000
        const val SCAN_REQUEST_PERMISSION = 2021
        const val SCAN_REQUEST_BLUETOOTH_ENABLE = 2022
        const val CONNECT_REQUEST_PERMISSION = 2023
        const val CONNECT_REQUEST_BLUETOOTH_ENABLE = 2024
        const val PAIR_REQUEST_PERMISSION = 2025
        const val PAIR_REQUEST_BLUETOOTH_ENABLE = 2025
    }

    private lateinit var activity: Activity
    private lateinit var methodResult: MethodResult
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var isScanning = false
    private var scanPeriod = DEFAULT_SCAN_PERIOD
    private val handler = Handler(Looper.getMainLooper())
    private val mDevices: MutableMap<String, BluetoothDeviceCache> = HashMap()

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        tearDown()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bleprint_android")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        bluetoothManager =
            flutterPluginBinding
                .applicationContext
                .getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?

        bluetoothAdapter = bluetoothManager!!.adapter

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            bluetoothLeScanner = bluetoothAdapter!!.bluetoothLeScanner
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        tearDown()
    }

    private fun tearDown() {
        channel.setMethodCallHandler(null)
        context = null
        methodResult.dispose()
        bluetoothAdapter = null
        bluetoothManager = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        methodResult = MethodResult(result)

        if (!isMethodValid(call)) return

        when (call.method) {
            "getPlatformName" -> methodResult.success("Android")
            "isAvailable" -> methodResult.success(bluetoothAdapter != null)
            "isEnabled" -> methodResult.success(bluetoothAdapter!!.isEnabled)
            "scan" -> {
                scanPeriod = (call.arguments as Int).toLong()
                startScan()
            }
            "paired" -> getBondedDevices()
            "connect" -> connect(call.arguments)
            "disconnect" -> disconnect(call.arguments)
            else -> result.notImplemented()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        val isGranted = grantResults[0] == PackageManager.PERMISSION_GRANTED
        when (requestCode) {
            SCAN_REQUEST_PERMISSION -> if (isGranted) startScan() else errorPermission()
            PAIR_REQUEST_PERMISSION -> if (isGranted) getBondedDevices() else errorPermission()
            CONNECT_REQUEST_PERMISSION -> {}
        }
        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val isResultOk = resultCode == Activity.RESULT_OK
        when (requestCode) {
            SCAN_REQUEST_BLUETOOTH_ENABLE -> if (isResultOk) startScan() else errorBluetoothEnable()
            PAIR_REQUEST_BLUETOOTH_ENABLE -> if (isResultOk) getBondedDevices() else errorBluetoothEnable()
            CONNECT_REQUEST_BLUETOOTH_ENABLE -> {}
        }
        return false
    }

    private fun isMethodValid(@NonNull call: MethodCall): Boolean {
        if (bluetoothAdapter == null && "isAvailable" != call.method) {
            methodResult.sendError("bluetooth_unavailable", "Bluetooth is unavailable")
            return false
        }
        return true
    }

    private fun errorPermission() {
        val msg = "is required location permissions"
        methodResult.sendError("no_permissions", msg)
    }

    private fun errorBluetoothEnable() {
        val msg = "is required Bluetooth enable"
        methodResult.sendError("bluetooth_disabled", msg)
    }

    private fun isPermissionGranted(requestCode: Int): Boolean {
        val isGranted = PackageManager.PERMISSION_GRANTED
        val locationCoarse = Manifest.permission.ACCESS_FINE_LOCATION

        val bluetooth =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Manifest.permission.BLUETOOTH_SCAN
            else Manifest.permission.BLUETOOTH

        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                locationCoarse,
                bluetooth,
                Manifest.permission.BLUETOOTH_CONNECT,
            )
        } else arrayOf(locationCoarse, bluetooth)

        if (ContextCompat.checkSelfPermission(context!!, locationCoarse) != isGranted ||
            ContextCompat.checkSelfPermission(context!!, bluetooth) != isGranted
        ) {
            ActivityCompat.requestPermissions(activity, permissions, requestCode)
            return false
        }
        return true
    }

    private fun isBluetoothEnable(requestCode: Int): Boolean {
        bluetoothAdapter?.takeIf { !it.isEnabled }?.apply {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            activity.startActivityForResult(enableBtIntent, requestCode)
            return false
        }
        return true
    }

    private fun isLeScannerAvailable(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (bluetoothLeScanner == null) {
                methodResult.sendError("bluetoothLe_scanner", "BluetoothLeScanner is unavailable")
                return false
            }
        }
        return true
    }

    private fun startScan() {
        if (!isPermissionGranted(SCAN_REQUEST_PERMISSION))
            return
        if (!isBluetoothEnable(SCAN_REQUEST_BLUETOOTH_ENABLE))
            return
        if (!isLeScannerAvailable())
            return
 
        if (isScanning) {
            stopScan()
            scanLeDevice()
        } else {
            scanLeDevice()
        }
    }

    private fun scanLeDevice() {
        handler.postDelayed({
            stopScan()
            channel.invokeMethod("onStopScan", false)
        }, scanPeriod)

        isScanning = true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (bluetoothLeScanner == null) return
            val settings =
                ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()

            val filters: List<ScanFilter> = ArrayList()
            bluetoothLeScanner!!.startScan(filters, settings, scanCallback)
        } else {
            bluetoothAdapter!!.startLeScan(leScanCallback)
        }
        methodResult.success(null)
    }

    private fun stopScan() {
        if (bluetoothLeScanner == null) return
        if (!isScanning) return

        isScanning = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            bluetoothLeScanner!!.stopScan(scanCallback)
        } else {
            bluetoothAdapter!!.stopLeScan(leScanCallback)
        }
    }

    private val leScanCallback: LeScanCallback = LeScanCallback { device, _, _ ->
        val map = Device.toJson(device)
        if (map != null) {
            activity.runOnUiThread { channel.invokeMethod("onScanResult", map) }
        }
    }

    private val scanCallback: ScanCallback = @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val map = Device.toJson(result.device)

            if (map != null) {
                activity.runOnUiThread { channel.invokeMethod("onScanResult", map) }
            }
        }

        override fun onScanFailed(errorCode: Int) {
            Logger.error("onScanFailed: error code: $errorCode", null)
        }
    }

    private fun getBondedDevices() {
        if (!isPermissionGranted(PAIR_REQUEST_PERMISSION))
            return
        if (!isBluetoothEnable(PAIR_REQUEST_BLUETOOTH_ENABLE))
            return

        val devices: MutableList<MutableMap<String, Any>?> = ArrayList()
        for (device in bluetoothAdapter!!.bondedDevices) {
            val map = Device.toJson(device)
            devices.add(map)
        }

        methodResult.success(devices)
    }

    private fun getPeripheral(address: String?): BluetoothDevice? {
        if (address == null) {
            methodResult.sendError("bluetooth_address_null", "address cannot be null")
            return null
        }

        val device = bluetoothAdapter!!.getRemoteDevice(address)
        if (device == null) {
            methodResult.sendError("bluetooth_address_not_found", "the device address is not found")
            return null
        }
        return device
    }

    private fun connect(arguments: Any) {
        if (!isPermissionGranted(PAIR_REQUEST_PERMISSION))
            return
        if (!isBluetoothEnable(PAIR_REQUEST_BLUETOOTH_ENABLE))
            return

        val arg = arguments as ArrayList<*>
        val address = arg[0] as String?
        val timeOut = (arg[1] as Int).toLong()

        val device = getPeripheral(address) ?: return
        if (isScanning)
            stopScan()

        val autoConnect = true
        val deviceId = device.address
        val isConnected: Boolean =
            bluetoothManager!!.getConnectedDevices(BluetoothProfile.GATT).contains(device)

        if (mDevices.containsKey(deviceId) && isConnected) {
            methodResult.sendError("already_connected", "connection with device already exists")
            return
        }
 
        if (mDevices.containsKey(deviceId) && !isConnected) {
            if (!mDevices[deviceId]!!.gatt!!.connect()) {
                methodResult.sendError("reconnect_error", "error when reconnecting to device")
                return
            }
        }

        val gattServer: BluetoothGatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            device.connectGatt(
                context,
                autoConnect,
                gattCallback,
                BluetoothDevice.TRANSPORT_LE
            )
        } else {
            device.connectGatt(context, autoConnect, gattCallback)
        }

        handler.postDelayed({
            val state: Int = bluetoothManager!!.getConnectionState(device, BluetoothProfile.GATT)
            if (state == BluetoothProfile.STATE_DISCONNECTED) {
                gattServer.disconnect()
                gattServer.close()
            }
        }, timeOut)

        mDevices[device.address] = BluetoothDeviceCache(gattServer)
        methodResult.success(null)
    }

    private fun disconnect(arguments: Any) {
        if (!isPermissionGranted(PAIR_REQUEST_PERMISSION))
            return
        if (!isBluetoothEnable(PAIR_REQUEST_BLUETOOTH_ENABLE))
            return

        val address = arguments as String?
        val device = getPeripheral(address) ?: return
        if (isScanning)
            stopScan()

        val deviceId = device.address
        val state: Int = bluetoothManager!!.getConnectionState(device, BluetoothProfile.GATT)
        val cache = mDevices.remove(deviceId)

        if (cache != null) {
            val gattServer = cache.gatt
            gattServer!!.disconnect()
            if (state == BluetoothProfile.STATE_DISCONNECTED) {
                gattServer.close()
            }
        }
        methodResult.success(null)
    }

    private val gattCallback: BluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            Logger.log("[onConnectionStateChange] newState: $newState")

            if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                if (!mDevices.containsKey(gatt!!.device.address)) {
                    gatt.close()
                }
            }

            val device = Device.toJson(gatt!!.device, newState)
            activity.runOnUiThread { channel.invokeMethod("onDeviceState", device) }
        }
    }
}