package com.dewinjm.bleprint

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothAdapter.LeScanCallback
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
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
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var isScanning = false
    private var scanPeriod = DEFAULT_SCAN_PERIOD
    private val handler = Handler(Looper.getMainLooper())

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {}
    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bleprint_android")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        val bluetoothManager =
            flutterPluginBinding
                .applicationContext
                .getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?

        bluetoothAdapter = bluetoothManager!!.adapter

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            bluetoothLeScanner = bluetoothAdapter!!.bluetoothLeScanner
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
        methodResult.dispose()
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

        methodResult.success(null)
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

            bluetoothLeScanner!!.startScan(null, settings, scanCallback)
        } else {
            bluetoothAdapter!!.startLeScan(leScanCallback)
        }
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
}