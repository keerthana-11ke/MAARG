package com.maarg.maarg

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import android.os.Build
import android.view.KeyEvent
import android.view.WindowManager
import android.content.Context
import android.os.Bundle
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL_SMS = "com.maarg.maarg/sms"
    private val CHANNEL_SOS = "maarg/sos"
    
    private var volumePressCount = 0
    private var lastPressTime = 0L
    private val resetDelay = 3000L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupLockScreenFlags()
    }

    private fun setupLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SMS).setMethodCallHandler { call, result ->
            if (call.method == "sendSMS") {
                val message = call.argument<String>("message")
                val recipients = call.argument<List<String>>("recipients")
                
                if (message != null && recipients != null && recipients.isNotEmpty()) {
                    try {
                        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            context.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }
                        
                        for (recipient in recipients) {
                            smsManager.sendTextMessage(recipient, null, message, null, null)
                        }
                        result.success("SMS Sent Successfully")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", "Failed to send SMS: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Message or recipients missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val currentTime = System.currentTimeMillis()
            
            // Reset if too much time passed
            if (currentTime - lastPressTime > resetDelay) {
                volumePressCount = 0
            }
            
            lastPressTime = currentTime
            volumePressCount++
            
            // Show toast feedback
            when (volumePressCount) {
                1 -> showToast("SOS: 1/3")
                2 -> showToast("SOS: 2/3")
                3 -> {
                    volumePressCount = 0
                    triggerSOS()
                    return true
                }
            }
            return true // consume the event
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun showToast(message: String) {
        try {
            Toast.makeText(
                this, message, 
                Toast.LENGTH_SHORT
            ).show()
        } catch (e: Exception) {
            // ignore
        }
    }

    private fun triggerSOS() {
        try {
            // Vibrate phone strongly (1000ms) safely
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(android.os.VibrationEffect.createOneShot(1000, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(1000)
            }
        } catch (e: Exception) {
            // ignore
        }

        try {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                val channel = MethodChannel(messenger, CHANNEL_SOS)
                // Post to main thread safely
                runOnUiThread {
                    try {
                        channel.invokeMethod("sos_triggered", null)
                    } catch (e: Exception) {
                        // Channel not ready yet, ignore
                    }
                }
            }
        } catch (e: Exception) {
            // Fail silently, never crash
        }
    }
}
