package com.example.face_native.data

import android.content.Context
import android.util.Log
import io.objectbox.BoxStore
import java.io.File

object ObjectBoxStore {
    private var _store: BoxStore? = null
    private var currentTenantKey: String? = null

    val store: BoxStore
        get() = _store ?: throw IllegalStateException("ObjectBoxStore not initialized. Call init() first.")

    val isInitialized: Boolean
        get() = _store != null

    fun init(context: Context, tenantKey: String): Boolean {
        // Check if already initialized with the same tenant key
        if (isInitialized && currentTenantKey == tenantKey) {
            Log.e("ObjectBoxStore", "Already initialized with same tenant key: $tenantKey")
            return true // Already initialized with same tenant key
        }

        // Close existing store if initialized with different tenant key
        if (isInitialized && currentTenantKey != tenantKey) {
            Log.e("ObjectBoxStore", "Re-initializing ObjectBoxStore with new tenant key: $tenantKey")
            _store?.close()
            _store = null
            currentTenantKey = null
        }

        return try {
            Log.e("ObjectBoxStore", "Initializing ObjectBoxStore with tenant key: $tenantKey")
            val dir = File(context.filesDir, "objectbox_$tenantKey")
            if (!dir.exists()) dir.mkdirs()
            _store = MyObjectBox.builder()
                .androidContext(context)
                .directory(dir)
                .build()
            currentTenantKey = tenantKey
            true
        } catch (e: Exception) {
            android.util.Log.e("ObjectBoxStore", "Failed to initialize ObjectBoxStore", e)
            false
        }
    }

    fun close() {
        _store?.close()
        _store = null
        currentTenantKey = null
    }
}
