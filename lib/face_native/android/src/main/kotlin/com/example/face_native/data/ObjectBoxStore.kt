package com.example.face_native.data

import android.content.Context
import android.util.Log
import io.objectbox.BoxStore
import java.io.File

object ObjectBoxStore {
    private var _store: BoxStore? = null

    val store: BoxStore
        get() = _store ?: throw IllegalStateException("ObjectBoxStore not initialized. Call init() first.")

    val isInitialized: Boolean
        get() = _store != null

    fun init(context: Context): Boolean {
        if (isInitialized) {
            Log.e("ObjectBoxStore", "Already initialized")
            return true
        }

        return try {
            Log.e("ObjectBoxStore", "Initializing ObjectBoxStore")
            val dir = File(context.filesDir, "objectbox")
            if (!dir.exists()) dir.mkdirs()
            _store = MyObjectBox.builder()
                .androidContext(context)
                .directory(dir)
                .build()
            true
        } catch (e: Exception) {
            android.util.Log.e("ObjectBoxStore", "Failed to initialize ObjectBoxStore", e)
            false
        }
    }

    fun close() {
        _store?.close()
        _store = null
    }
}
