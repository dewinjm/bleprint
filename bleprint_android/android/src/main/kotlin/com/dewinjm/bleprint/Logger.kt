package com.dewinjm.bleprint

import android.util.Log

object Logger {
    var TAG = "BleprintPlugin"

    fun log(message: String) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, message)
        }
    }

    fun error(message: String, throwable: Throwable?) {
        if (BuildConfig.DEBUG) {
            Log.e(TAG, message, throwable)
        }
    }
}