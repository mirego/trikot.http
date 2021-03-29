package com.mirego.trikot.http.android

import android.util.Log
import io.ktor.client.features.logging.Logger

class AndroidHttpLogger : Logger {
    override fun log(message: String) {
        Log.d("HTTP", message)
    }
}
