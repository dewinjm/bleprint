package com.dewinjm.bleprint

import io.flutter.plugin.common.MethodChannel

class MethodResult(result: MethodChannel.Result) {
    private var result: MethodChannel.Result? = null

    init {
        this.result = result
    }

    fun sendError(code: String, message: String) {
        result!!.error(code, message, null)
        Logger.error(code, Throwable(message))
        dispose()
    }

    fun success(obj: Any?) {
        result!!.success(obj)
    }

    fun dispose() {
        result = null
    }
}