package com.papierkram.timetracker

import android.os.Bundle
import android.os.Build
import android.view.ViewTreeObserver
import android.view.WindowManager

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val flutter_native_splash = true
        var originalStatusBarColor = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            originalStatusBarColor = window.statusBarColor
            window.statusBarColor = 0xffa9c4cd.toInt()
        }
        val originalStatusBarColorFinal = originalStatusBarColor

        GeneratedPluginRegistrant.registerWith(this)
        val vto = flutterView.viewTreeObserver
        vto.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                flutterView.viewTreeObserver.removeOnGlobalLayoutListener(this)
                window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    window.statusBarColor = originalStatusBarColorFinal
                }
            }
        })

    }
}
