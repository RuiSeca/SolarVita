package com.solarvitadev.solarvita

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle

class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle Health Connect permissions rationale
        val providerPackageName = "com.google.android.apps.healthdata"
        
        val intent = Intent().apply {
            action = "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"
            setPackage(providerPackageName)
            data = Uri.parse("package:${packageName}")
        }
        
        startActivity(intent)
        finish()
    }
}