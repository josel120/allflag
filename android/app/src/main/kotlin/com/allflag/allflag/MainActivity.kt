package com.allflag.allflag

import android.content.res.Configuration
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var flagModeRequested = false
    private var foreground = false
    private var applied: Boolean? = null
    private var flagModeChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flagModeChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.allflag.allflag/flag_mode"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "setFlagMode") {
                    result.notImplemented()
                } else {
                    val active = call.arguments as? Boolean
                    if (active == null) {
                        result.error("invalid_argument", "Expected a boolean", null)
                    } else {
                        flagModeRequested = active
                        applyFlagMode()
                        result.success(null)
                    }
                }
            }
        }
    }

    private fun applyFlagMode(force: Boolean = false) {
        // Guard against late Dart messages while paused or rotating out of landscape.
        val active = flagModeRequested && foreground && hasWindowFocus() &&
            resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        if (!force && applied == active) return
        val insets = WindowCompat.getInsetsController(window, window.decorView)
        if (active) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            insets.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            insets.hide(WindowInsetsCompat.Type.systemBars())
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            insets.show(WindowInsetsCompat.Type.systemBars())
            insets.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_DEFAULT
        }
        applied = active
    }

    override fun onPostResume() {
        super.onPostResume()
        foreground = true
        // Flutter restores its own overlay defaults in super.onPostResume().
        applyFlagMode(force = true)
    }

    override fun onPause() {
        foreground = false
        applyFlagMode()
        super.onPause()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        applyFlagMode()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyFlagMode()
    }

    override fun onDestroy() {
        flagModeRequested = false
        applyFlagMode()
        flagModeChannel?.setMethodCallHandler(null)
        flagModeChannel = null
        super.onDestroy()
    }
}
