package com.solarvitadev.solarvita

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val HEALTH_CONNECT_CHANNEL = "solar_vitas/health_connect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_CONNECT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchHealthConnectIntent" -> {
                        val action = call.argument<String>("action")
                        if (action != null) {
                            val success = launchHealthConnectIntent(action)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Action cannot be null", null)
                        }
                    }
                    "launchHealthPermissionIntent" -> {
                        val action = call.argument<String>("action")
                        val packageName = call.argument<String>("packageName")
                        if (action != null && packageName != null) {
                            val success = launchHealthPermissionIntent(action, packageName)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Action and packageName cannot be null", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun launchHealthConnectIntent(action: String): Boolean {
        return try {
            val intent = Intent(action).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            
            // Check if intent can be resolved
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                // Try with Health Connect package explicitly
                intent.setPackage("com.google.android.apps.healthdata")
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    true
                } else {
                    false
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun launchHealthPermissionIntent(action: String, packageName: String): Boolean {
        return try {
            val intent = Intent(action).apply {
                putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            
            // Check if intent can be resolved
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                // Try with Health Connect package explicitly  
                intent.setPackage("com.google.android.apps.healthdata")
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    true
                } else {
                    false
                }
            }
        } catch (e: Exception) {
            false
        }
    }
}
